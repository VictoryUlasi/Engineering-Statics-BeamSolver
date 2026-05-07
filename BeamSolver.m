%Simple Pin-Roller BeamSolver

%Declerations
dist_load = [];

% Beam
L = input('Enter Beam Length: ');% length

% Loads
try
    str = input("Enter Force values: ",'s');
    force_mag = sscanf(str,'%f')';   % magnitudes, sscanf returns a column vector by default, transposing force_mag and force_pos when you read them in allows to concatenate horizontally
    str = input("Enter lever arm distance for Forces: ",'s');
    force_pos = sscanf(str, '%f')';  % positions along beam 

    % Four defining values per distributed load (w1 w2 start stop)
    % Start position
    % End position
    % Intensity at start (w1)
    % Intensity at end (w2)
    str = input("Enter signed (+,-) Distributed Loads (w1 w2 start stop): ", 's');
    [dist_loads_values , count] = sscanf(str, '%f'); %all distributed load values and how many items in the array

    if(length(force_mag) ~= length(force_pos)), error("***# Of Forces has to equal # Of Positions!");end
    if(mod(count,4) ~= 0), error("***Each Distributed load needs four defining values!");end

catch ME
    disp(ME.message);
    return;
end

% Parse Distributed Loads and store them in a structure
if (count ~= 0)
    for i = 1:(count/4)
        idx = (i-1)*4 + 1; %logic to always loop in n (idx = (i-1)*n + 1)
        dist_load(i).w1 = dist_loads_values(idx);
        dist_load(i).w2 = dist_loads_values(idx+1);
        dist_load(i).start = dist_loads_values(idx+2);
        dist_load(i).stop = dist_loads_values(idx+3);
    end
end

% Track number of real point loads before appending equivalent distributed loads
% This prevents double counting in the shear loop
n_point_loads = length(force_mag);

% Solve distributed loads to turn them into equivalent force and position
% using area of a trapezoid which can basically turn into area of a
% rectangle and triangle depending on the intensities at the start and stop
% positions
for i = 1:(length(dist_load))
    F_eq = ((dist_load(i).w1 + dist_load(i).w2)/2) * (dist_load(i).stop - dist_load(i).start);
    x_bar = ((dist_load(i).w1 + (2*dist_load(i).w2))/(3*(dist_load(i).w1 + dist_load(i).w2))) * (dist_load(i).stop - dist_load(i).start); % x_bar = ((w1 + 2*w2) / (3*(w1 + w2))) * (stop - start) **Centroid Integral CH10 Statics
    F_eq_pos = dist_load(i).start + x_bar; %converts from local coordinates (measured from load start) to global beam coordinates.

    force_mag = [force_mag F_eq];
    force_pos = [force_pos F_eq_pos];
end

% Supports
support_type = [1, 2];          % 1=pin, 2=roller
support_pos = [0, L];           % positions along beam


%Matrix of Unknowns
A = [1  0   0;       % sum Fx
     0  1   1;       % sum Fy
     0  0   L];      % sum moments about pin

b = [0;
     -sum(force_mag);
     -sum(force_mag .* force_pos)];

x = A\b; % reads as solve Ax = b for x

Px = x(1);
Py = x(2);
Ry = x(3);

%Shear Val Solver
X = linspace(0,L,1000);
shear_val = zeros(1,length(X));

for i = 1:length(X)
    value = 0;

    for j = 1:n_point_loads % Point loads only, equivalent dist loads excluded to avoid double counting
        if (force_pos(j) <= X(i))
            value = value + force_mag(j);
        end
    end

    for k = 1:length(support_pos) %% Support shear value loop
        if(support_pos(k) <= X(i))
            switch support_type(k)
                case 1
                    value = value + Py;
                case 2
                    value = value + Ry;
            end
        end
    end

    for m = 1:length(dist_load) % Distributed load continuous shear contribution
        if (X(i) <= dist_load(m).start)
            % Before load, contribute nothing
            contribution = 0;
        elseif (X(i) >= dist_load(m).stop)
            % Past load, contribute full F_eq
            contribution = ((dist_load(m).w1 + dist_load(m).w2)/2) * (dist_load(m).stop - dist_load(m).start);
        else
            % Inside load, partial trapezoid area from start to X(i)
            d = X(i) - dist_load(m).start;
            w_at_x = dist_load(m).w1 + ((dist_load(m).w2 - dist_load(m).w1) / (dist_load(m).stop - dist_load(m).start)) * d;
            contribution = ((dist_load(m).w1 + w_at_x) / 2) * d;
        end
        value = value + contribution;
    end

    shear_val(i) = value;
end

%Moments Calculations
dX = X(2) - X(1); %To get step size

%shear_val is already an arr of shear values at every X of the beam, Moment is the area under shear value V distance graph
%since shear_val and X are evenly spaced and X is just hold the distance
%information for shear_val multiplying every shear_val by the change in X
%which would be the same at any 2 points, would give me the moment at every
%X on the beam, cumsum simply creates an array cumulatively summing
%everything to the left

moment_val = cumsum(shear_val .* dX); 
%Initially didint make sense becuase i havent taken solid mechanics,
%but basically this is the moment at every point on the beam, since the
%beam is in EQ it should go from 0 to 0, and the highest moment tells you
%where the beam is most likely to fail 
%Highest moment = Highest Bending stress = Most likely fail location
%sigma = Mc/I;M is your bending moment, c is the distance from the neutral axis, and I is the moment of inertia of the cross section

moment_val(end) = 0; %this is to force small numerical error from cumsum i think?, moment at right end should be 0 since beam is in equilibrium

%fyi in statics we find moment at point A due to all forces, used to find unknowns
%this moment is the internal moment at every cross section, used to find where the beam might fail

try
pos = input('Enter position to generate values from: ');
if ((pos > L)), error('Position Entered Cannot Be Greater than Beam Length!');end
if ((pos < 0)), error('Position Entered Cannot Be Negative!');end
idx = max(1,min(1000,round((pos/L)*1000))); %Force index to be between 1 : 1000; if pos = 0 idx = 1, if pos = 1000 idx = 1000; Round is for inputs like (1/3) = 33.3
fprintf("Shear Value at %.2fm = %.2fN\n", pos,shear_val(idx))
fprintf("Moment at %.2fm = %.2fNm\n", pos,moment_val(idx))
catch ME
    disp(ME.message)
end


%Plots
f = figure;
f.Name = 'Beam Solver';
f.NumberTitle = 'Off';

%Plot 1 (Shear)
subplot(2,1,1)
plot(X,shear_val,'-r','LineWidth',3)
title('Shear Value vs Length')
xlabel('Length(m)')
ylabel('Shear Value(N)')
grid on
yline(0,'--','y=0', 'LineWidth',2);
set(gca,'FontSize',12,'FontName', 'Helvetica')

%Plot 2 (Moment)
subplot(2,1,2)
plot(X,moment_val,'--b','LineWidth',3)
title('Moment vs Length')
xlabel('Length(m)')
ylabel('Moment(Nm)')
grid on
yline(0,'--','y=0', 'LineWidth',2);
set(gca,'FontSize',12,'FontName', 'Helvetica')