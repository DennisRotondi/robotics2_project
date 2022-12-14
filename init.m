addpath(genpath("utils"))
% gravity terms
g0 = 9.81;
g = g0*[0;-1;0];

% robot kinematic parameters
l1 = 1;
l2 = 1;
l3 = 1;
l = [l1;l2;l3];

% motor dynamic parameters
% include reduction ratios?
Im1 = 1;
Im2 = 1;
Im3 = 1;

% robot dynamic parameters
m1 = 10;
m2 = 7.5;
m3 = 5;
m = [m1;m2;m3];

d1 = -0.5;
d2 = -0.5;
d3 = -0.5;
I = zeros(3,3,3);
I(3,3,1) = (1/12)*m(1)*l1*l1;
I(3,3,2) = (1/12)*m(2)*l2*l2;
I(3,3,3) = (1/12)*m(3)*l3*l3;

% viscous friction coefficients
f1 = 0;
f2 = 0;
f3 = 0;

friction = [f1;f2;f3];

q = sym('q',[3,1]); assume(q,"real");
dq = sym('dq',[3,1]); assume(dq,"real");
ddq = sym('ddq',[3,1]); assume(ddq,"real");
u  = sym('u',[3,1]); assume(u,"real");

table = [0 l1 0 q(1);
         0 l2 0 q(2);
         0 l3 0 q(3)];

[T,dkin] = DHplus(table);

r = [d1 d2 d3; 0 0 0; 0 0 0];

% set up simulation using euler lagrange ( do only once )

[vc,om] = moving_frames(table,[0,0,0], r,q,dq) ;

[~,M] = kinM(vc,om,[m1;m2;m3],I,dq);

invM = inv(M);

c = christoffel(M,q,dq)*dq;
gr = gravity_terms(m,g,r,T,q);

% ddq = (invM*(u-c-gr)); 
ddq = (M\(u-c-gr));

open("RRR_rigid_joints")
% https://it.mathworks.com/help/symbolic/generate-matlab-function-blocks.html
matlabFunctionBlock("RRR_rigid_joints/Direct Dynamics/euler_lagrange",ddq,"vars",[u q dq])

%% state and regulation parameters
% you can fine-tune launching only this part of the file ctrl+send
iteration_period = 5;
gamma = 3.01;
beta = 1/6;

% stiffness coefficients
k1 = 1500;
k2 = 1000;
k3 = 500;

k = [k1;k2;k3];

% initial state
q0 = [-pi/2;0;0];
% theta0 at steady state is related to q0 by:
theta0 = double(diag(k)^-1*subs(gr,q,q0)+q0);

dq0 = [0;0;0];
dtheta0 = [0;0;0];

% gain matrices
Kp = [400;400;400];
Kd = [400;400;350];

% desired set-point
qd = [pi/4;0;0];
