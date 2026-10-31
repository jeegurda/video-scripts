# vmaf

[vmaf.sh](./vmaf.sh) compares two videos with FFmpeg's `libvmaf` filter and plots the per-frame VMAF score.

## Requirements

- `jq`
- `gnuplot` (`sudo apt install gnuplot-nox`)
- An FFmpeg build with the `libvmaf` filter, available as **`ffmpeg-vmaf`**

## Setup (Linux / WSL)

Download a static FFmpeg build that includes `libvmaf` from [johnvansickle.com/ffmpeg](https://johnvansickle.com/ffmpeg/):

```bash
mkdir -p ~/apps
cd ~/apps
curl -L -o ffmpeg.tar.xz \
  https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz
tar -xJf ffmpeg.tar.xz
```

Link its `ffmpeg` binary under the name the script expects. Adjust the directory name to match the version you extracted:

```bash
mkdir -p ~/.local/bin
ln -sf ~/apps/ffmpeg-7.0.2-amd64-static/ffmpeg ~/.local/bin/ffmpeg-vmaf
```

Make sure `~/.local/bin` is on your `PATH`:

```bash
echo "$PATH" | tr ':' '\n' | grep local/bin
```

If it isn't, add it:

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

Verify:

```bash
command -v ffmpeg-vmaf
ffmpeg-vmaf -hide_banner -filters 2>&1 | grep libvmaf
```

The second command should print a `libvmaf` line.

## Usage

Run from this directory, because the script loads the model from the relative path `vmaf_v0.6.1.json`:

```bash
cd vmaf
./vmaf.sh --distorted encode.mp4 --reference original.mp4
./vmaf.sh -d encode.mp4 -r original.mp4 -s 0:30 -S 0:30 -t 10
```

**Distorted** is the encode being judged; **reference** is the original. The order matters.

| Short | Long                | Default | Meaning                                   |
| ----- | ------------------- | ------- | ----------------------------------------- |
| `-d`  | `--distorted`       |         | Distorted video                           |
| `-r`  | `--reference`       |         | Reference video                           |
| `-s`  | `--distorted-start` | `1:00`  | Start offset in the distorted video       |
| `-S`  | `--reference-start` | `1:00`  | Start offset in the reference video       |
| `-t`  | `--duration`        | `30`    | Length in seconds of the compared segment |
| `-n`  | `--name`            | `1`     | Prefix for the output files               |
| `-h`  | `--help`            |         | Show usage                                |

Outputs are written to `<name>-vmaf-log.json`, `<name>-vmaf-data.txt` and `<name>-plot.png` (for example `1-vmaf-log.json`), so files for the same run sort together. Run `./clean.sh` to delete all of them.
