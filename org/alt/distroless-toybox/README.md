ALT distroless-toybox image
===========================

This is distroless image with toybox binary. It can be used for debugging
containers as toybox provide a lot of utils.

To launch shell in the container:
`docker run --rm -it registry.altlinux.org/alt/distroless-toybox`

To get system inforamtion:
`docker run --rm -it registry.altlinux.org/alt/distroless-toybox uname -a`
