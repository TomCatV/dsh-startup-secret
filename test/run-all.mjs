#!/usr/bin/env node
/**
 * test/run-all.mjs — 一键跑全部测试并汇总
 *
 * 2026-10-29 追加（优化项 4）。上游 npm test 是 `node a && node b && ...` 串联：
 * 任一条挂了看不到完整报告，也不知道总共多少断言。这里逐条跑、逐条统计。
 *
 * 用法：
 *   node test/run-all.mjs           # 跳过需要交互输入的那条
 *   node test/run-all.mjs --all     # 全跑（含 verify-password.mjs）
 */
import { spawnSync } from 'node:child_process'
import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const testDir = path.dirname(fileURLToPath(import.meta.url))
const wantAll = process.argv.includes('--all')

/** 需要交互输入 / 依赖外部宿主的，默认跳过 */
const INTERACTIVE = new Set(['verify-password.mjs'])

const files = fs
  .readdirSync(testDir)
  .filter((f) => f.endsWith('.mjs') && f !== 'run-all.mjs')
  .sort()

const rows = []
let totalPass = 0
let totalFail = 0
let skipped = 0

for (const file of files) {
  if (INTERACTIVE.has(file) && !wantAll) {
    skipped += 1
    rows.push({ file, status: 'skip', note: '需交互输入，用 --all 强制跑' })
    continue
  }

  const started = Date.now()
  const run = spawnSync(process.execPath, [path.join(testDir, file)], {
    encoding: 'utf8',
    timeout: 180_000,
    env: { ...process.env, NO_COLOR: '1' }
  })
  const ms = Date.now() - started
  const out = `${run.stdout || ''}${run.stderr || ''}`

  // 上游测试统一输出「通过 N / 失败 M」
  const m = out.match(/通过\s*(\d+)\s*\/\s*失败\s*(\d+)/)
  const pass = m ? Number(m[1]) : 0
  const fail = m ? Number(m[2]) : 0
  const ok = run.status === 0 && fail === 0

  totalPass += pass
  totalFail += fail

  rows.push({
    file,
    status: ok ? 'pass' : 'FAIL',
    pass,
    fail,
    ms,
    note: ok ? '' : (out.trim().split('\n').filter((l) => /FAIL|Error|✗/.test(l)).slice(0, 3).join(' | ') || `exit ${run.status}`)
  })
}

const pad = (s, n) => String(s).padEnd(n)
console.log('')
console.log('  ' + pad('测试文件', 28) + pad('结果', 10) + pad('断言', 10) + '耗时')
console.log('  ' + '─'.repeat(64))
for (const r of rows) {
  const res = r.status === 'pass' ? '通过' : r.status === 'skip' ? '跳过' : '失败'
  const cnt = r.pass !== undefined ? `${r.pass}/${r.pass + r.fail}` : '-'
  const time = r.ms !== undefined ? `${(r.ms / 1000).toFixed(1)}s` : ''
  console.log('  ' + pad(r.file, 28) + pad(res, 10) + pad(cnt, 10) + time + (r.note ? '  ' + r.note : ''))
}
console.log('  ' + '─'.repeat(64))
console.log(`  合计：通过 ${totalPass} 项断言，失败 ${totalFail} 项，跳过 ${skipped} 个文件`)
console.log('')

process.exit(totalFail === 0 && !rows.some((r) => r.status === 'FAIL') ? 0 : 1)
