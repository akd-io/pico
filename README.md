# AKD's Picotron projects

## Picotron

### Findings

I'm documenting my findings on Picotron as I go in [`findings.md`](picotron/findings.md). These include hidden and undocumented features, as well as differences to Pico-8.

A few shortcuts to documentation `findings.md` also links to:

- [`stat()` Documentation](picotron/drive/projects/stat/stats.md)
- [Picotron CLI Documentation](picotron/drive/projects/cli/cli.md)
- [`_signal()` Documentation](picotron/drive/projects/signal/signal.md)

### Setup

This sections covers my own setup for working on Picotron in the repository.

#### Picotron drive setup

This repo stores a picotron drive at `picotron/drive`. To use this as your Picotron drive, and commit changes to the repo, update your `picotron_config.txt` to point to this repo's `picotron/drive` folder.

On my machine, `picotron_config.txt` was located at `/Users/akd/Library/Application Support/Picotron/picotron_config.txt`, and I updated it to:

```
# picotron config

mount / /Users/akd/workspace/pico/picotron/drive
```

#### Accessing root folder in host OS

Because we have remapped the drive folder mount, we don't have easy access to the root Picotron folder (parent of the `drive` folder) when running the `folder` command in Picotron.

The root folder can be accessed using:

- `open "/Users/akd/Library/Application Support/Picotron"`
