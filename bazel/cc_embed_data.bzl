# Part of the Crubit project, under the Apache License v2.0 with LLVM
# Exceptions. See /LICENSE for license information.
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

"""Open-source stand-in for the Google-internal `cc_embed_data` rule.

Embeds `srcs` in a `cc_library` named `name`. For outputs `<base>.h` and
`<base>.cc`, the header declares:

    struct FileToc { const char* name; const char* data; size_t size; };
    const FileToc* <base>_create();  // One entry per src, keyed by basename.
    size_t <base>_size();

`data` is NUL-terminated. Any other `outs` (e.g. an internal `.o`) are ignored.
"""

load("@rules_cc//cc:cc_library.bzl", "cc_library")

def cc_embed_data(name, srcs, outs, **kwargs):
    hdr = [o for o in outs if o.endswith(".h")][0]
    cc = [o for o in outs if o.endswith(".cc")][0]
    base = hdr[:-len(".h")].split("/")[-1]
    guard = (native.package_name() + "/" + hdr).upper().replace("/", "_").replace(".", "_") + "_"

    native.genrule(
        name = name + "_gen",
        srcs = srcs,
        outs = [hdr, cc],
        cmd = """
cat > $(location {hdr}) <<'EOF'
#ifndef {guard}
#define {guard}
#include <cstddef>
#ifndef FILE_TOC_DEFINED_
#define FILE_TOC_DEFINED_
struct FileToc {{
  const char* name;
  const char* data;
  size_t size;
}};
#endif
const FileToc* {base}_create();
size_t {base}_size();
#endif  // {guard}
EOF
out=$(location {cc})
echo '#include "{pkg}/{hdr}"' > $$out
i=0
for f in $(SRCS); do
  echo "static const char kData$$i[] = {{" >> $$out
  od -An -v -tx1 "$$f" | sed -E 's/ *([0-9a-f]{{2}})/0x\\1,/g' >> $$out
  echo "0x00}};" >> $$out
  i=$$((i+1))
done
echo "static const FileToc kToc[] = {{" >> $$out
i=0
for f in $(SRCS); do
  echo "  {{\\"$$(basename $$f)\\", kData$$i, sizeof(kData$$i) - 1}}," >> $$out
  i=$$((i+1))
done
echo "  {{nullptr, nullptr, 0}}}};" >> $$out
echo "const FileToc* {base}_create() {{ return kToc; }}" >> $$out
echo "size_t {base}_size() {{ return $$i; }}" >> $$out
""".format(hdr = hdr, cc = cc, base = base, guard = guard, pkg = native.package_name()),
    )

    cc_library(
        name = name,
        srcs = [cc],
        hdrs = [hdr],
        **kwargs
    )
