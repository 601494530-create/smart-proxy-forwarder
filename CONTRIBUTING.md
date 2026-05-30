# Contributing Guide

## Code Style

- Python: follow PEP 8, 4-space indent, max 100 chars per line
- Shell: use `bash` with `set -euo pipefail`, 4-space indent

## How to Contribute

1. Fork the repo
2. Create a feature branch: `git checkout -b my-feature`
3. Make your changes
4. Run syntax check: `python3 -c "import py_compile; py_compile.compile('proxy_forwarder.py')"`
5. Commit with clear message
6. Push and open a Pull Request

## Testing

Currently there is no formal test suite. When adding features, please include
basic tests under `tests/`.

## Release Process

1. Update `VERSION` in `proxy_forwarder.py`
2. Update `pyproject.toml` version
3. Tag: `git tag -a vX.Y.Z -m "vX.Y.Z"`
4. Push: `git push && git push --tags`

## Reporting Issues

Include:
- Python version (`python3 --version`)
- OS / WSL version
- How you started the forwarder (command line or config file)
- Full error output from `/tmp/proxy-forwarder.log`
