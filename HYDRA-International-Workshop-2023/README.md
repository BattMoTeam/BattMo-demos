# Running the BattMo.jl demo
The demo is a Pluto notebook. Navigate to this folder in a terminal, launch Julia and point it to this environment:
```
julia --project=.
```
You can then run the following command to add Pluto and run the notebook. On subsequent runs it is sufficient to only run the part that starts with `using Pluto`.
```julia
using Pkg; Pkg.add("Pluto"); using Pluto; Pluto.run(notebook="battmo_demo.jl")
```
