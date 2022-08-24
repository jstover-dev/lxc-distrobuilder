# LXC Image Builder

Builder for Alpine and Debian LXC containers.

## Supported Images

- Alpine (latest supported releases)
- Debian 11 (WIP)

## Usage

### Install Dependencies

```shell
pip install -r requirements.txt
```

### Build Images

```shell

# Build all supported images
make images

# Build only Alpine images
make alpine

# Build only Debian images
make debian

# Build specific Alpine version
ALPINE_VERSIONS=3.16.2 make alpine
```

### Upload to remote host

```shell
UPLOAD_HOST=example.com UPLOAD_PATH=remote/image/path make upload
```