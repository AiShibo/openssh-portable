The command used to configure the OpenSSH. This enables two features: kerneros5 and pam, because they they will enable more handlers, which gives us more code to fuzz. This configure also provides the correct path when forking unprivileged compartments.

```bash
./configure --with-kerberos5 \
            --with-pam \
            --prefix="$PWD" \
            --sbindir="$PWD" \
            --libexecdir="$PWD" \
            --sysconfdir="$PWD" \
            CFLAGS="$CFLAGS" LDFLAGS="$LDFLAGS"
```
Command used to fuzz the program:

```bash
afl-fuzz \
  -i in \
  -o findings \
  -g 4000 \
  -m none \
  -- $(pwd)/sshd-session -R
```

