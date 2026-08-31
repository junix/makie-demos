set shell := ["bash", "-euo", "pipefail", "-c"]

default: build

# Render every demo into out/ (run `just instantiate` once after cloning).
build:
    julia --project=. tools/render.jl

# The Julia test suite, which re-checks the rendered outputs.
test: build
    julia --project=. -e 'using Pkg; Pkg.test()'

# Demos repo — no binary, no launcher (ADR-749: nothing to install).
install:
    @echo "makie-demos: demos repo, nothing to install"

# Resolve and precompile the Julia environment (slow; run once after cloning).
instantiate:
    julia --project=. -e 'using Pkg; Pkg.instantiate(); Pkg.precompile()'

# Remove generated images.
clean:
    rm -rf out
    mkdir -p out
    touch out/.gitkeep
