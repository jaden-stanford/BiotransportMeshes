clc;
clear;

% Tutorial 1: Laminar Flow Past Cylinder
% QuickerSim CFD Toolbox for MATLAB(R) Tutorial
%
% <http://www.quickersim.com/cfd-toolbox-for-matlab/index>.
%
% This tutorial is intended for the free and full version of the toolbox.


% Import mesh generated by Gmsh
% p, e, t arrays store the computational mesh. 
% Type 'help importMeshGmsh' in Matlab console for details.
tic
[p,e,t] = importMeshGmsh('Part1Cylinder.msh');

% Display
%mesh 1
%displayMesh2D(p,t);

% Convert mesh to second order (refer to Tutorial 10 for details)
% nVnodes - number velocity nodes in the mesh (2nd order mesh)
% nPnodes - number of pressure nodes  (1st order mesh)
% indices - structure to extract data later on
[p,e,t,nVnodes,nPnodes,indices] = convertMeshToSecondOrder(p,e,t);

x_scale = 0.8;
y_scale = 1.5;
x0 = -2;
y0 = -2;

p(1,:) = (p(1,:)-x0)*x_scale + x0;
p(2,:) = (p(2,:)-y0)*y_scale + y0;

figure(1)
displayMesh2D(p, t);


% kinematic viscosity of the fluid:
nu = 0.01; 
% For our geometry and velocity this implies Re = 100

% Initialize solution
% u stores velocity and pressure
[u, convergence] = initSolution(p,t,[1 0],0);

% Make absolute residuals drop below 1e-3, however don't allow for more than 25 
% iterations.red34w23-e==============================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================sssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssss3cdwx89
maxres = 1e-5;
maxiter = 50;

% Start iterations
for iter = 1:maxiter
    % Assemble Navier-Stokes matrix and right-hand side vector
    % u(indices.indu) accesses x-velocities in the solution vector
    % u(indices.indv) accesses y-velocities in the solution vector
   
    [NS, F] = assembleNavierStokesMatrix2D(p,e,t,nu,u(indices.indu),u(indices.indv),'nosupg');  % 'nosupg' flag tells that we do not use any kind of SUPG stabilization
    
    % Apply boundary conditions
    [NS, F] = imposeCfdBoundaryCondition2D(p,e,t,NS,F,1,'inlet', [1 0]);  % Inlet at wall 10 with velocity set to [1 0]
    [NS, F] = imposeCfdBoundaryCondition2D(p,e,t,NS,F,3,'slipAlongX');  % Free slip along x axis on channel walls (wall id = 12)
    [NS, F] = imposeCfdBoundaryCondition2D(p,e,t,NS,F,4,'wall');  % No-slip wall boundary condition at cylinder walls (id = 13)
    
    % Do nothing for outflow at boundary with id = 11 - pressure outlet as default
    
    % Compute and plot residuals
    [stop, convergence] = computeResiduals(NS,F,u,size(p),convergence,maxres);
    plotResiduals(convergence,2);
    
    % Break if solution converged
    if(stop)
        break;
    end
    
    % Solve equations
    u = NS\F;
end

% Displaying and Exporting Solution Fields

% Generate pressure data in all mesh nodes:
pressure = generatePressureData(u,p,t);

% Display x-velocity to figure(3)
figure(3)
displaySolution2D(p,t,u(indices.indu),'x-velocity field [m/s]')

% Display pressure field to figure(4)
figure(4)
displaySolution2D(p,t,u(indices.indp),'pressure divided by density')

% Export velocity vector field to Gmsh
exportToGmsh2D('velocityVector.msh',[u(indices.indu); u(indices.indv)],p,t,'velocity_vector');

exportToGmsh2D('velocity_y_component.msh',u(indices.indv),p,t,'y-velocity');
exportToGmsh2D('pressure.msh',pressure,p,t,'pressure field');
toc
[I, av] = boundaryIntegral2D(p, e, pressure, 1)