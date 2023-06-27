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
Set your discharge modifier as a percentage below. The discharge curve is quickly updated after a full fast simulation is run using BattMo.jl!
"


# ╔═╡ 58a378b1-9bcc-4779-a1d9-8a9919df4a41
@bind c_delta Slider(range(-0.1, 10.0, length = 100), default = 0.0)

# ╔═╡ c90f74ed-35ac-4cb3-a52f-dc80624fea4e


# ╔═╡ f0891d30-3e0d-4218-b727-5e85bccb340e
md"""
# Visualize the P2D particle model
Drag the slider to show the concentration values at different discretization nodes.
"""

# ╔═╡ d6bab3df-c3e2-47b2-aa0f-854ee8617155
@bind particle_index Slider(1:10, default = 1)

# ╔═╡ 678b6f59-0bf7-48a0-afb1-51370a6f2871


# ╔═╡ a73c7c2b-ac66-4b78-a0a7-36cb73637764
_, _, extra = run_battery_1d(info_level = -1, end_report = true, extra_timing = false);

# ╔═╡ 84f62ddf-46bb-41c2-8d2a-fd5615c2a7d3


# ╔═╡ 74263966-438a-4e42-9ebd-0e840077b8e9


# ╔═╡ 28d1cb26-1cbf-4c96-9e4e-3eb1f20edad0
html"""
<style>
input[type*="range"] {
	width: 100%;
}
</style>
"""


# ╔═╡ d9c74eb9-138d-4449-ba8b-a127ac08a0c0
function get_cap(states, dt)
	E    = [state[:BPP][:Phi][1] for state in states]
	I    = [state[:BPP][:Current][1] for state in states]
	cap  = cumsum(I.*dt)/3600 # in Ah
end

# ╔═╡ 71a806ef-53af-4012-b1c7-37d2b24498b8
begin
	state0 = extra[:state0]
	parameters = extra[:parameters]
	sim = extra[:simulator]
	model = sim.model
	config = extra[:config]
	forces = extra[:forces]    

	cap    = BattMo.computeCellCapacity(model)
    con    = BattMo.Constants()
	function simulate_with_crate(c)
	    inputI = (cap/con.hour)*c
	
	    # @. state0[:BPP][:Phi] = minE*1.5
	    minE = jsondict["Control"]["lowerCutoffVoltage"]
	    tup = Float64(jsondict["TimeStepping"]["rampupTime"])
	    cFun(time) = BattMo.currentFun(time, inputI, tup)
	
		n = 100
		total = con.hour/c*1.2
	    dt = total/n
	    timesteps = BattMo.rampupTimesteps(total, dt, 5);    
	    time = cumsum(timesteps)
	
	    currents = setup_forces(model[:BPP], policy = SimpleCVPolicy(cFun, minE))
	    forces_new = setup_forces(model, BPP = currents) 
	
		s, r = simulate!(sim, timesteps, config = config, forces = forces_new, state0 = state0)
		return (s, time, timesteps, r)
	end
	c0 = 0.1
	states, time0, timesteps0, reports0 = simulate_with_crate(c0)
	cap0 = get_cap(states, timesteps0)
	E    = [state[:BPP][:Phi][1] for state in states]

	CRate  = c0 + c_delta
    states_new, time, timesteps, reports = simulate_with_crate(CRate)

	cap_new = get_cap(states_new, timesteps)
	
	E_new = [state[:BPP][:Phi][1] for state in states_new];
end

# ╔═╡ 64f8cc10-b20e-460d-a0cd-07077e3d808e
stats = Jutul.report_stats(reports);

# ╔═╡ ef9d0c67-8dae-4b67-8471-0dbcea7da9c1
time_spent = @sprintf "%3.1f ms" stats.time_sum.total*1000

# ╔═╡ 35eeff7c-1145-4172-b2a5-6614edba2547
begin
	# f = x -> x[:ELYTE][:C]
	f1 = x -> x[:NAM][:Cp][particle_index, :]
	f2 = x -> x[:PAM][:Cp][particle_index, :]
	f3 = x -> x[:ELYTE][:C]

	x1 = map(f1, states_new)
	x2 = map(f2, states_new)
	x3 = map(f3, states_new)

	p1 = contourf(hcat(x1...)', title = "Negative active material")
	p2 = contourf(hcat(x2...)', title = "Positive active material")
	p3 = contourf(hcat(x3...)', title = "Electrolyte")

	l = @layout [grid(1,2)
             b{0.5h}
	]
	plot(p1, p2, p3, layout = l)
end

# ╔═╡ 25bfa365-36e8-41fd-a5b8-2a2f8b80b720
perc = @sprintf "%3.2f" c0+c_delta

# ╔═╡ 5e2111b7-9585-43a6-9ada-1d0fa7a5a49f
md"
### Your current discharge rate is $(perc)!
Last simulation performed $(stats.newtons) Newton iterations in $time_spent
"

# ╔═╡ 5b602e28-12ae-4d78-ab4d-9bd460ae442b
function computeEnergy(states, timesteps)
	E    = [state[:BPP][:Phi][1] for state in states]
	I    = [state[:BPP][:Current][1] for state in states]

    Emid = (E[2 : end] + E[1 : end - 1])/2 
    Imid = (I[2 : end] + I[1 : end - 1])/2

    return sum(Emid.*Imid.*timesteps[1 : end - 1])/3600 
end

# ╔═╡ aa97a563-e004-4c34-9a59-485a7029f046
begin
	energy_base = computeEnergy(states, timesteps0)
	energy_new = computeEnergy(states_new, timesteps)
	a = plot(cap0, E, label = "CRate = $c0", lw = 3)
	plot!(cap_new, E_new, label = "Your choice", lw = 3, ls = :dash)
	tmp = @sprintf "%3.2f" c_delta
	title!("C-Rate = $perc (base case: $c0)")
	xlabel!("Capacity / Ah")
	ylabel!("Voltage / V")
	b = bar([energy_base, energy_new], orientation = :h, legend = false)
	ylims!(0, 2.5)
	xlabel!("Recovered energy / Wh")
	xlims!(0.5*min(energy_base, energy_new), 1.1*max(energy_base, energy_new))
	yticks!([1, 2], ["Base case", "Your choice"])
	plot(a, b, layout = grid(2, 1, heights=[0.8, 0.2]))
end


# ╔═╡ Cell order:
# ╟─752a8f85-e7a8-4fce-9b8f-c3089d18967a
# ╟─24b9f4ef-ab5c-4c80-af83-f16884a27732
# ╟─aa97a563-e004-4c34-9a59-485a7029f046
# ╟─5e5f8eff-344e-4760-ac12-558ffc1344ee
# ╠═58a378b1-9bcc-4779-a1d9-8a9919df4a41
# ╟─5e2111b7-9585-43a6-9ada-1d0fa7a5a49f
# ╠═c90f74ed-35ac-4cb3-a52f-dc80624fea4e
# ╟─64f8cc10-b20e-460d-a0cd-07077e3d808e
# ╟─f0891d30-3e0d-4218-b727-5e85bccb340e
# ╠═d6bab3df-c3e2-47b2-aa0f-854ee8617155
# ╟─35eeff7c-1145-4172-b2a5-6614edba2547
# ╟─103007f0-144b-11ee-02df-6ff3fc7c0678
# ╟─678b6f59-0bf7-48a0-afb1-51370a6f2871
# ╠═e4d7976f-2e67-4119-a809-74b5e12d0d5c
# ╟─114c991c-3a32-4311-ba82-b48a6487c473
# ╟─ad84c33c-61a3-4533-965e-f19b0922f52f
# ╟─47bdbfc9-d3d9-48d0-b300-57ef4b98969c
# ╟─edec07c4-6e80-499a-92ec-c748dccfa34c
# ╠═1431be70-414f-4189-8674-3556a5728d32
# ╠═a73c7c2b-ac66-4b78-a0a7-36cb73637764
# ╠═71a806ef-53af-4012-b1c7-37d2b24498b8
# ╠═84f62ddf-46bb-41c2-8d2a-fd5615c2a7d3
# ╠═77ba22b5-35aa-4195-a0e2-4ba40406a04c
# ╠═74263966-438a-4e42-9ebd-0e840077b8e9
# ╠═25bfa365-36e8-41fd-a5b8-2a2f8b80b720
# ╠═ef9d0c67-8dae-4b67-8471-0dbcea7da9c1
# ╠═28d1cb26-1cbf-4c96-9e4e-3eb1f20edad0
# ╠═d9c74eb9-138d-4449-ba8b-a127ac08a0c0
# ╠═5b602e28-12ae-4d78-ab4d-9bd460ae442b
