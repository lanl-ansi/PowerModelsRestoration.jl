%
% Tests when a large shunt needs to shed to ensure AC feasiblity
% removing line 3-2 requires shunt shedding for feasibilty
%

function mpc = case3_mld_s
mpc.version = '2';
mpc.baseMVA = 100.0;

%% bus data
%	bus_i	type	Pd	Qd	Gs	Bs	area	Vm	Va	baseKV	zone	Vmax	Vmin
mpc.bus = [
	1	 3	 0.0	 00.0	 0.0	 0.0	 1	    1.00000	   0.00000	 240.0	 1	    1.10000	    0.90000;
	2	 2	 100.0	 50.0	 1.0	-30.0	 1	    1.00000	   0.00000	 240.0	 1	    1.10000	    0.90000;
	3	 2	 100.0	 50.0	 0.0	-30.0	 1	    1.00000	   0.00000	 240.0	 1	    1.10000	    0.90000;
];
%column_names%  damaged 
mpc.bus_damage = [
	0;
	0;
	0;
];

%% generator data
%	bus	Pg	Qg	Qmax	Qmin	Vg	mBase	status	Pmax	Pmin	Pc1	Pc2	Qc1min	Qc1max	Qc2min	Qc2max	ramp_agc	ramp_10	ramp_30	ramp_q	apf
mpc.gen = [
	1	 0.000	 0.000	 1000.0	 -1000.0	 1.00000	 100.0	 1	 100.0	 0.0	 0.0	 0.0	 0.0	 0.0	 0.0	 0.0	 0.0	 0.0	 0.0	 0.0	 0.0;
	3	 0.000	 0.000	 1000.0	 -1000.0	 1.00000	 100.0	 1	 50.0	 0.0	 0.0	 0.0	 0.0	 0.0	 0.0	 0.0	 0.0	 0.0	 0.0	 0.0	 0.0;
];
%column_names%  damaged
mpc.gen_damage = [
	1;
	1;
];

%% generator cost data
%	2	startup	shutdown	n	c(n-1)	...	c0
mpc.gencost = [
	2	 0.0	 0.0	 3	   0.000000	  10.000000	   0.000000;
	2	 0.0	 0.0	 3	   0.000000	   1.000000	   0.000000;
];

%% branch data
%	fbus	tbus	r	x	b	rateA	rateB	rateC	ratio	angle	status	angmin	angmax
mpc.branch = [
	1	 3	 0.065	 0.62	 0.0	 30.0	 0.0	 0.0	 0.0	 0.0	 1	 -30.0	 30.0;
	3	 2	 0.025	 0.75	 0.0	 30.0	 0.0	 0.0	 0.0	 0.0	 0	 -30.0	 30.0;
	1	 2	 0.042	 0.9	 0.0	 60.0	 0.0	 0.0	 0.0	 0.0	 1	 -30.0	 30.0;
	1	 2	 0.042	 0.9	 0.0	 60.0	 0.0	 0.0	 0.0	 0.0	 1	 -30.0	 30.0;
];

%column_names%  damaged
mpc.branch_damage = [
	1;
	1;
	1;
	1;
];


% hours
mpc.time_elapsed = 1.0

%% storage data
%   storage_bus ps qs energy  energy_rating charge_rating  discharge_rating  charge_efficiency  discharge_efficiency  thermal_rating  qmin  qmax  r  x  p_loss  q_loss  status
mpc.storage = [
	1	 0.0	 0.0	 20.0	 100.0	 50.0	 70.0	 0.8	 0.9	 100.0	 -50.0	 70.0	 0.1	 0.0	 0.0	 0.0	 1;%
	1	 0.0	 0.0	 30.0	 100.0	 50.0	 70.0	 0.9	 0.8	 100.0	 -50.0	 70.0	 0.1	 0.0	 0.0	 0.0	 1;
];
%column_names%  damaged
mpc.storage_damage = [
	1;
	1;
];
