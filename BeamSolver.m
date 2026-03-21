%Simple Pin-Roller BeamSolver

%Test values for forces Delete later*********** and get input
F1 = -18;
F2 = -82;
F3 = -150;
x1 = 1;
x2 = 2;
x3 = 8;

% Beam
L = 10;                         % length

% Loads
force_mag = [F1, F2, F3];      % magnitudes
force_pos = [x1, x2, x3];      % positions along beam

% Supports
support_type = [1, 2];          % 1=pin, 2=roller
support_pos = [0, L];           % positions along beam


A = [1  0   0;       % sum Fx
     0  1   1;       % sum Fy
     0  0   L];      % sum moments about pin

b = [0;
     -sum(force_mag);
     -sum(force_mag .* force_pos)];

x = A\b;

Px = x(1);
Py = x(2);
Ry = x(3);

%Shear Val Solver
X = linspace(0,L,1000);
shearval = zeros(1,length(X));

for i = 1:length(X)
    value = 0;
    for j = 1:length(force_pos) %%Force shear value loop
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
    shearval(i) = value;
end

try
pos = input('Enter position to calculate Shear Value: ');
if ((pos > L) || (pos < L)), error('Impossible Position Entered!\n');end
idx = max(1,min(1000,round((pos/L)*1000))); %Force index to be between 1 : 1000; if pos = 0 idx = 1, if pos = 1000 idx = 1000; Round is for inputs like (1/3) = 33.3
fprintf("Shear Value at %.2fm = %.2fN\n", pos,shearval(idx))
catch ME
    disp(ME.message)
end

f = figure;
f.Name = 'Beam Solver';
f.NumberTitle = 'Off';
plot(X,shearval,'-r','LineWidth',3)

title('Shear Value vs Length')
xlabel('Length(m)')
ylabel('Shear Value(N)')
grid on
yline(0,'--','y=0', 'LineWidth',2);

set(gca,'FontSize',15,'FontName', 'Helvetica')
