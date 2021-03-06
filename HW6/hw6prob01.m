function hw6prob01
clear all
clc;

% %%%%%%%%%%%%%%%%%%
% PARAMETERS
%
% - state-space system
params.A = [0 1; 0 -1/5];
params.B = [0; 1/5];
params.C = [1 0];
% - time step
params.dt = 1e-2;
%
% %%%%%%%%%%%%%%%%%%

RunSimulation(2,params);


function [u,userdata] = ControlLoop(y,r,userdata,params)
%

%
A = [0 1;0 -.2];
B = [0;.2];
C = [1 0];
Qc = [6000, 0;0 .001];
Rc = .00004999;
Qo = 10000;
Ro = 2*eye(2);


K = lqr(A,B,Qc,Rc);
L = lqr(A',C',inv(Ro),inv(Qo))';

persistent isFirstTime
if isempty(isFirstTime)
    isFirstTime = false;
    fprintf(1,'initialize control loop\n');
    userdata.K = K;
    userdata.kref = -inv(params.C*inv(params.A-params.B*userdata.K)*params.B);
    userdata.L = L;
    userdata.xhat = [-1;2];
    
end
u = -userdata.K * userdata.xhat + userdata.kref*r;
userdata.xhat = userdata.xhat + params.dt * (params.A * userdata.xhat + params.B * u - (userdata.L * (params.C * userdata.xhat - y)));




function RunSimulation(tmax,params)
% - define reference signal
r = pi/2;
% - define initial condition
x = [0; 0];
% - create array of times
t = 0:params.dt:tmax;
% - initialize userdata as an empty structure
userdata = struct;
% - define state-space system
sys = ss(params.A,params.B,params.C,0);
% - get initial measurement
y = params.C*x;
% - initialize array to store outputs
ysto = y;
% - initialize figure
fig = UpdateRobot([],ysto,t,1);
% - iterate to run simulation
for i=2:length(t)
    
    % Get input
    [u,userdata] = ControlLoop(y,r,userdata,params);
    
    % Get state
    x = OneStep(x,u,sys,params.dt);
    
    % Get measurement
    y = params.C*x;
    
    % Store
    ysto(:,end+1) = y;
    
    % Display
    fig = UpdateRobot(fig,ysto,t,i);
    
end

function x = OneStep(x,u,sys,dt)
[ytemp,ttemp,xinitial] = initial(sys,x,[0 dt]);
xinitial = xinitial';
[ytemp,ttemp,xstep] = step(sys,[0 dt]);
xstep = xstep';
x = xinitial(:,end) + u*xstep(:,end);

function fig = UpdateRobot(fig,y,t,icur)
if (isempty(fig))
    % Create figure
    clf;
    fig.leftaxes = subplot(1,2,1);
    set(gcf,'renderer','opengl');
    axis equal;
    axis(1*[-1 1 -1 1 -0.05 0.5]);
    axis manual;
    hold on;
    view([90-37.5,20]);
    % Make axes pretty
    set(gca,'xtick',[],'ytick',[],'ztick',[]);
    box on;
    set(gca,'projection','perspective');
    % Create robot
    [p,f,c] = makebox(1,0.25,0.1,[0.25;0;0.175]);
    fig.obj(1) = MakeObj(p,f,c);
    [p,f,c] = makebox(0.1,0.35,0.2,[0.8;0;0.175]);
    fig.obj(end+1) = MakeObj(p,f,c);
    [p,f,c] = makebox(0.1,0.05,0.15,[0.9;0.075;0.175]);
    fig.obj(end+1) = MakeObj(p,f,c);
    [p,f,c] = makebox(0.1,0.05,0.15,[0.9;-0.075;0.175]);
    fig.obj(end+1) = MakeObj(p,f,c);
    [p,f,c] = makecylinder(0.075,0.25,[0;0;.125]);
    fig.obj(end+1) = MakeObj(p,f,c);
    [p,f,c] = makebox(0.75,0.75,0.025,[0;0;0]);
    fig.obj(end+1) = MakeObj(p,f,c);
    fig.nobj = 4;
    fig.title = title(sprintf('t = %.2f',t(icur)),'fontsize',18);
    fig.rightaxes = subplot(1,2,2);
    axis([t(1) t(end) -pi pi]);
    axis manual;
    hold on;
    set(gca,'fontsize',18);
    box on;
    xlabel('time');
    ylabel('angle');
    set(gca,'xtick',0:1:t(end));
    set(gca,'ytick',[-pi -pi/2 0 pi/2 pi]);
    set(gca,'yticklabel',{'-\pi','-\pi/2','0','\pi/2','\pi'});
    fig.output = plot(t(1:icur),y(1:icur),'linewidth',2);
    grid on;
end
R = rotZ(y(icur));
for i=1:fig.nobj
    p0 = R*fig.obj(i).p;
    set(fig.obj(i).h,'vertices',p0');
    set(fig.output,'xdata',t(1:icur),'ydata',y(1:icur));
end
% axes(fig.leftaxes);
set(fig.title,'string',sprintf('t = %.2f',t(icur)));
drawnow;

function R = rotX(h)
R = [1 0 0; 0 cos(h) -sin(h); 0 sin(h) cos(h)];

function R = rotY(h)
R = [cos(h) 0 sin(h); 0 1 0; -sin(h) 0 cos(h)];

function R = rotZ(h)
R = [cos(h) -sin(h) 0; sin(h) cos(h) 0; 0 0 1];

function obj = MakeObj(p,f,c)
obj.p = p;
obj.f = f;
obj.c = c;
obj.h = patch('Vertices',p','Faces',f,'CData',c,'FaceColor','flat');

function [verts,faces,colors] = makebox(x,y,z,delta)
verts = [0 x x 0 0 x x 0; 0 0 0 0 y y y y; 0 0 z z 0 0 z z];
verts(1,:) = verts(1,:)-(x/2);
verts(2,:) = verts(2,:)-(y/2);
verts(3,:) = verts(3,:)-(z/2);
verts = verts + repmat(delta,1,size(verts,2));
faces = [1 2 3 4; 2 6 7 3; 6 5 8 7; 5 1 4 8; 4 3 7 8; 5 6 2 1];
colors(:,:,1) = 1*ones(1,size(faces,1));
colors(:,:,2) = 1*ones(1,size(faces,1));
colors(:,:,3) = 0*ones(1,size(faces,1));
colors(1,5,1) = 1;
colors(1,5,2) = 0;
colors(1,5,3) = 0;

function [verts,faces,colors] = makecylinder(radius,height,delta)
[x,y,z] = cylinder(radius,10);
x = x(:)';  y = y(:)'; 
z(1,:) = -height/2; z(2,:)= height/2; z = z(:)';
nverts = length(x);
nfaces = (length(x)-2) / 2;
verts = [x; y; z];
verts = verts + repmat(delta,1,size(verts,2));
faces = nan(nfaces,nverts/2);
faces(:,1) = 1:2:nverts-2; 
faces(:,2) = 3:2:nverts; 
faces(:,3) = 4:2:nverts; 
faces(:,4) = 2:2:nverts-2;
faces(end+1,:) = 1:2:nverts; 
faces(end+1,:) = 2:2:nverts;
nfaces = nfaces + 2;
colors = zeros(1,nfaces,3);
colors(:,:,1) = 1;
colors(:,end,2) = 1;
colors(:,end-1,1) = 0.5;