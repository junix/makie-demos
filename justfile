render:
    julia --project=. scripts/render.jl

test:
    julia --project=. -e 'using Pkg; Pkg.test()'

instantiate:
    julia --project=. -e 'using Pkg; Pkg.instantiate(); Pkg.precompile()'
