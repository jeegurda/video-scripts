// @ts-check
import { spawn } from 'child_process'
import { join, parse } from 'path'
import { readFile } from 'fs'
import minimist from 'minimist'
import { detectNewline } from 'detect-newline'
import chalk from 'chalk'

const isTimestamp = (str) =>
  str.match(/^\d{1,2}:\d{1,2}(\.\d+)?(:\d{1,2}?(\.\d+)?)?$/)

const argv = minimist(process.argv)

const inpFile = argv.i
const dir = argv.d
const dry = argv.dry || true

const cmds = []

if (!inpFile) {
  console.error('Input file not provided (-i)')
  process.exit(1)
}

if (!dir) {
  console.error('Directory not provided (-d)')
  process.exit(1)
}

/**
 * @param {string} cmd
 * @returns {Promise<void>}
 */
const run = (cmd) => {
  return new Promise((resolve, reject) => {
    const child = spawn(cmd, { shell: true, stdio: 'inherit' })

    child.on('exit', (code) => {
      console.log(`child process exited with code ${code}`)
      if (code !== 0) {
        reject(new Error(`Command failed with exit code ${code}`))
      } else {
        resolve()
      }
    })

    child.on('error', (err) => {
      console.error(`Failed to start subprocess. ${err}`)
      reject(err)
    })
  })
}

readFile(inpFile, 'utf8', async (err, data) => {
  if (err) {
    console.error(err)
    process.exit(1)
  }

  const nl = detectNewline(data) || '\n'
  const parsedFiles = data.split(nl.repeat(2))

  parsedFiles.forEach((line) => {
    let counter = 0
    const re = new RegExp(`(.*?)${nl}(.*)`, 's')
    const match = line.match(re)

    if (!match || !match[1] || !match[2]) {
      console.warn(chalk.yellow('bad line format: %o'), line)
      return
    }

    const [_, fileNameLine, segmentLines] = match

    if (fileNameLine.startsWith('#')) {
      console.log(chalk.green(`Skipping file #${fileNameLine}...`))
      return
    }

    const segments = segmentLines.split(nl)

    let hasValidTimes = false

    segments.forEach((segmentLine) => {
      let str = `ffmpeg -i "${join(dir, fileNameLine)}"`

      if (segmentLine === '') {
        // empty line, can be a valid case (e.g. last line)
        return
      }

      let [start, end] = segmentLine.split(/\s/)
      start = start.trim()
      end = end?.trim()

      if (!start) {
        console.warn(
          chalk.yellow('start time missing for fileName %o. Skipping'),
          fileNameLine,
        )
        return
      }

      if (!isTimestamp(start)) {
        console.warn(
          chalk.yellow(
            'bad start time format ("%o") for fileName %o. Skipping',
          ),
          start,
          fileNameLine,
        )
        return
      }

      if (end && !isTimestamp(end)) {
        console.warn(
          chalk.yellow('bad end time format ("%o") for fileName %o. Skipping'),
          end,
          fileNameLine,
        )
        return
      }

      hasValidTimes = true

      const finalName = `"${join(dir, parse(fileNameLine).name)}.${
        counter + 1
      }.mp4"`
      const ss = `-ss ${start} `
      const to = end ? `-to ${end} ` : ''
      str += ` ${ss}${to}-crf 17 -c:v libx264 -preset ultrafast ${finalName}`

      console.log(`${chalk.bgGreenBright('cmd:')} ${str}`)
      cmds.push(str)
      counter++
    })

    if (!hasValidTimes) {
      console.warn(
        chalk.yellow('all times are bad for the fileName %o. Skipping'),
        fileNameLine,
      )
      return
    }
  })

  console.log('')

  if (dry && dry !== 'false') {
    console.log(chalk.yellow('Dry run, "--dry false" to disable'))
    process.exit(0)
  }

  for (const cmd of cmds) {
    await run(cmd)
  }
})
