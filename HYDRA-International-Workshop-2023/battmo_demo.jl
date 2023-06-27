### A Pluto.jl notebook ###
# v0.19.26

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
end

# ╔═╡ 103007f0-144b-11ee-02df-6ff3fc7c0678
using Pkg

# ╔═╡ e4d7976f-2e67-4119-a809-74b5e12d0d5c
Pkg.add(name = "Plots", version = "1.38")

# ╔═╡ 114c991c-3a32-4311-ba82-b48a6487c473
Pkg.add("BattMo")

# ╔═╡ ad84c33c-61a3-4533-965e-f19b0922f52f
Pkg.add("Jutul")

# ╔═╡ 47bdbfc9-d3d9-48d0-b300-57ef4b98969c
Pkg.add("JSON")

# ╔═╡ edec07c4-6e80-499a-92ec-c748dccfa34c
Pkg.add("PlutoUI")

# ╔═╡ 1431be70-414f-4189-8674-3556a5728d32
using BattMo, Jutul, Plots, PlutoUI, Printf

# ╔═╡ 77ba22b5-35aa-4195-a0e2-4ba40406a04c
begin
	using JSON
	jsondict = JSON.parsefile(BattMo.defaultjsonfilename)
end

# ╔═╡ 752a8f85-e7a8-4fce-9b8f-c3089d18967a
md"
![BattMo logo](https://github.com/BattMoTeam/BattMo.jl/raw/main/docs/src/assets/battmologo_text.png)
"

# ╔═╡ 24b9f4ef-ab5c-4c80-af83-f16884a27732
md"
# 🔋 Welcome to the BattMo.jl demo 🔋
BattMo.jl is a Julia version of the BattMo toolbox that provides:
- Much faster performance
- No need for a MATLAB license
- Integration with Julia ecosystem, including optimization frameworks
"

# ╔═╡ 5e5f8eff-344e-4760-ac12-558ffc1344ee

md"
## Try adjusting the discharge rate
Set your discharge modifier as a percentage below. The discharge curve is immediately updated after a full fast simulation is run using BattMo.jl!
"


# ╔═╡ 58a378b1-9bcc-4779-a1d9-8a9919df4a41
@bind c_factor Slider(range(-90.0, 300.0, length = 500), default = 0.0)

# ╔═╡ c90f74ed-35ac-4cb3-a52f-dc80624fea4e


# ╔═╡ 678b6f59-0bf7-48a0-afb1-51370a6f2871


# ╔═╡ a73c7c2b-ac66-4b78-a0a7-36cb73637764
states, reports, extra = run_battery_1d(info_level = -1, end_report = true, extra_timing = false);

# ╔═╡ 63005f86-bd56-46e3-934f-57a10af8a060
begin
	state0 = extra[:state0]
	parameters = extra[:parameters]
	sim = extra[:simulator]
	model = sim.model
	config = extra[:config]
	forces = extra[:forces]
	timesteps0 = extra[:timesteps]
	time0 = cumsum(timesteps0)
	timesteps = repeat(timesteps0, 2)
    
    time = cumsum(timesteps)
    E    = [state[:BPP][:Phi][1] for state in states]
end

# ╔═╡ 71a806ef-53af-4012-b1c7-37d2b24498b8
begin
	cap    = BattMo.computeCellCapacity(model)
    con    = BattMo.Constants()

	CRate  = jsondict["Control"]["CRate"]*(100.0 + c_factor)/100.0
    inputI = (cap/con.hour)*CRate

    # @. state0[:BPP][:Phi] = minE*1.5
    minE = jsondict["Control"]["lowerCutoffVoltage"]
    tup = Float64(jsondict["TimeStepping"]["rampupTime"])
    cFun(time) = BattMo.currentFun(time, inputI, tup)
    
    currents = setup_forces(model[:BPP], policy = SimpleCVPolicy(cFun, minE))
    forces_new = setup_forces(model, BPP = currents) 

	states_new, report_new = simulate!(sim, timesteps, config = config, forces = forces_new, state0 = state0)
	
	E_new = [state[:BPP][:Phi][1] for state in states_new];
end

# ╔═╡ 64f8cc10-b20e-460d-a0cd-07077e3d808e
stats = Jutul.report_stats(report_new);

# ╔═╡ 74263966-438a-4e42-9ebd-0e840077b8e9


# ╔═╡ 25bfa365-36e8-41fd-a5b8-2a2f8b80b720
perc = @sprintf "%3.2f%%" 100+c_factor

# ╔═╡ aa97a563-e004-4c34-9a59-485a7029f046
begin
	plot(time0, E, label = "Base case", lw = 3)
	plot!(time, E_new, label = "Your choice", lw = 3, ls = :dash)
	tmp = @sprintf "%3.2f" c_factor
	title!("Discharge rate scale = $perc")
	xlabel!("Time / s")
	ylabel!("Voltage / V")
end


# ╔═╡ ef9d0c67-8dae-4b67-8471-0dbcea7da9c1
time_spent = @sprintf "%3.1f ms" stats.time_sum.total*1000

# ╔═╡ 5e2111b7-9585-43a6-9ada-1d0fa7a5a49f
md"
### Your current discharge rate is $(perc)!
Last simulation performed $(stats.newtons) Newton iterations in $time_spent
"

# ╔═╡ 28d1cb26-1cbf-4c96-9e4e-3eb1f20edad0
html"""
<style>
input[type*="range"] {
	width: 100%;
}
</style>
"""


# ╔═╡ Cell order:
# ╟─752a8f85-e7a8-4fce-9b8f-c3089d18967a
# ╟─24b9f4ef-ab5c-4c80-af83-f16884a27732
# ╟─aa97a563-e004-4c34-9a59-485a7029f046
# ╟─5e5f8eff-344e-4760-ac12-558ffc1344ee
# ╟─58a378b1-9bcc-4779-a1d9-8a9919df4a41
# ╟─5e2111b7-9585-43a6-9ada-1d0fa7a5a49f
# ╠═c90f74ed-35ac-4cb3-a52f-dc80624fea4e
# ╟─64f8cc10-b20e-460d-a0cd-07077e3d808e
# ╟─103007f0-144b-11ee-02df-6ff3fc7c0678
# ╟─678b6f59-0bf7-48a0-afb1-51370a6f2871
# ╠═e4d7976f-2e67-4119-a809-74b5e12d0d5c
# ╟─114c991c-3a32-4311-ba82-b48a6487c473
# ╟─ad84c33c-61a3-4533-965e-f19b0922f52f
# ╟─47bdbfc9-d3d9-48d0-b300-57ef4b98969c
# ╟─edec07c4-6e80-499a-92ec-c748dccfa34c
# ╠═1431be70-414f-4189-8674-3556a5728d32
# ╠═a73c7c2b-ac66-4b78-a0a7-36cb73637764
# ╠═63005f86-bd56-46e3-934f-57a10af8a060
# ╠═71a806ef-53af-4012-b1c7-37d2b24498b8
# ╠═77ba22b5-35aa-4195-a0e2-4ba40406a04c
# ╠═74263966-438a-4e42-9ebd-0e840077b8e9
# ╠═25bfa365-36e8-41fd-a5b8-2a2f8b80b720
# ╠═ef9d0c67-8dae-4b67-8471-0dbcea7da9c1
# ╠═28d1cb26-1cbf-4c96-9e4e-3eb1f20edad0
