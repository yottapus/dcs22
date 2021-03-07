clear all;close all;clc
rng(1)
NN = 5;

% min{z1...zN} sum{1,N}(ci'*zi)
% subj: 	sum{1,N} (Hi*zi)=b == sum{1,N}(Hi*zi-bi)=0
%       	zi € Pi, i€{1...N}

% Hi*zi-bi==gi(zi)

progenres.b=b;progenres.c=c;progenres.d=d;progenres.D=D;
progenres.H=H;progenres.LB=LB;progenres.UB=UB;



%%
% Centralized Solution

% centralized (parallel) dual subgradient:
% zi^t+1= argmin{zi € Pi}(ci'*zi +(mu^t)'*(Hi*zi-bi)
%       = argmin{zi € Pi}( ci'+(mu^t)'*Hi)*zi -(mu^t)'*bi)
% mu^t+1 = max {0, mu^t+alfa^t *sum{1,N}(Hi*zi^t+1 -bi) }


options = optimoptions('linprog','Display','none');
[~, fopt, exit_flag] = linprog(c,H,bb_centr,[],[],LB,UB,options);

if exit_flag ~= 1
  fprintf(2,'A problem occurred in the centralized solution\n');
  return;
end

fprintf('Centralized optimal cost is %.4g\n',fopt);

%%Primal problem

MAXITERS = 5e4;

ZZ = zeros(NN,MAXITERS); 
ZZ_RA = zeros(NN,MAXITERS);

alfa = zeros(MAXITERS,1);

primal_cost = zeros(MAXITERS,1);
dual_cost   = zeros(MAXITERS,1);
primal_cost_RA = zeros(MAXITERS,1);
dual_cost_RA   = zeros(MAXITERS,1);

tt_ra = 1;
NMIN=1;

for tt = 1:MAXITERS-1
  if mod(tt,100)==0
      fprintf('Iteration n. %d\n',tt);
  end
  % Primal Update
%   for ii=1:NN
%      XX(ii,tt) = linprog(cc_LP(ii)+MU(tt)*AA_LP(ii),[],[],[],[],LB(ii),UB(ii),options);
%   end
  for ii=1:NN
    if c(ii)+alfa(tt)*H(ii)>=0
        ZZ(ii,tt) = LB(ii);
    else
        ZZ(ii,tt) = UB(ii);
    end
  end
  
  % Running average
  for ii=1:NN
      if tt==1
          ZZ_RA(ii,tt) = ZZ(ii,tt);
      else
          ZZ_RA(ii,tt) = (1/tt)*((tt-1)*ZZ_RA(ii,tt-1)+ZZ(ii,tt));
      end
  end
%   
  % Dual Update
  % mu^{t+1} = mu^t + gamma^t* ( sum_i grad_q_i(mu^t) )
   alpha_t = 0.1*(1/tt)^0.6; % 1/tt^alpha with alpha in (0.5, 1]

  
  alfa(tt+1) = alfa(tt);
  for ii=1:NN
    grad_ii = ZZ(ii,tt)-b(ii);
    
    alfa(tt+1) = alfa(tt+1) + alpha_t*grad_ii;
  end
	alfa(tt+1) = max(0,alfa(tt+1));
  
  % Performance check

  for ii=1:NN
    ff_ii = c(ii)*ZZ(ii,tt);
    primal_cost(tt) = primal_cost(tt) + ff_ii;
    
    ff_ii = c(ii)*ZZ_RA(ii,tt);
    primal_cost_RA(tt) = primal_cost_RA(tt) + ff_ii;
    
    qq_ii = c(ii)*ZZ(ii,tt) + alfa(tt)*(ZZ(ii,tt)-b(ii));
    dual_cost(tt) = dual_cost(tt) + qq_ii;
    
    qq_ii = c(ii)*ZZ_RA(ii,tt) + alfa(tt)*(ZZ_RA(ii,tt)-b(ii));
    dual_cost_RA(tt) = dual_cost_RA(tt) + qq_ii;
  end
end
%%
% Last value [for plot]
tt = MAXITERS;
fprintf('Iteration n. %d\n',tt);
for ii=1:NN   
    ZZ(ii,tt) = linprog(c(ii)+alfa(tt)*H(ii),[],[],[],[],LB(ii),UB(ii),options);
    ZZ_RA(ii,tt) = (1/tt)*((tt-1)*ZZ_RA(ii,tt-1)+ZZ(ii,tt));
    ff_ii = c(ii)*ZZ(ii,tt);
    primal_cost(tt) = primal_cost(tt) + ff_ii;
    
    ff_ii = c(ii)*ZZ_RA(ii,tt);
    primal_cost_RA(tt) = primal_cost_RA(tt) + ff_ii;
    
    qq_ii = c(ii)*ZZ(ii,tt) + alfa(tt)*(ZZ(ii,tt)-b(ii));
    dual_cost(tt) = dual_cost(tt) + qq_ii;
    
    qq_ii = c(ii)*ZZ_RA(ii,tt) + alfa(tt)*(ZZ_RA(ii,tt)-b(ii));
    dual_cost_RA(tt) = dual_cost_RA(tt) + qq_ii;
end

figure
  semilogy(1:MAXITERS,abs(primal_cost(1:MAXITERS)-fopt), 'LineWidth',2);
  hold on, grid on, zoom on
  semilogy(1:MAXITERS,abs(primal_cost_RA(1:MAXITERS)-fopt), 'LineWidth',2);
  semilogy(1:MAXITERS,abs(dual_cost(1:MAXITERS)-fopt), 'LineWidth',2);
  semilogy(1:MAXITERS,abs(dual_cost_RA(1:MAXITERS)-fopt), 'LineWidth',2);
  xlabel('t')
  ylabel('cost error')
  legend('primal cost','primal cost with running avg','dual cost','dual cost with running avg')
  
%%
figure
  plot(1:MAXITERS,alfa, 'LineWidth',2);
  hold on, grid on, zoom on
  xlabel('t')
  ylabel('\mu_i^t')

%%
figure
  plot(1:MAXITERS,sum(ZZ,1)-bb_centr, 'LineWidth',2);
  hold on, grid on, zoom on
  plot(1:MAXITERS,sum(ZZ_RA,1)-bb_centr, 'LineWidth',2);
  xlabel('t')
  ylabel('x_1^t + ... + x_N^t - b')
  legend('x','x from running avg')

% return
%% dual function 
% (remove the return)
mu = 0:0.01:10;
dual_=zeros(numel(mu),1);

for mm = 1:numel(mu)
        [~, fopt, ~] = linprog(c+mu(mm)*ones(NN,1),[],[],[],[],LB,UB,options);
        dual_(mm) = fopt-mu(mm)*bb_centr;
end
    
figure
plot(mu,dual_);grid on;zoom on;
xlabel('\mu')
ylabel('q(\mu)')



%% comments
% xi^t (blue one) oscillates, not converging
% running avarage converges 
%       XX_RA(ii,tt) = (1/tt)*((tt-1)*XX_RA(ii,tt-1)+XX(ii,tt))
% mu^t converging as expected for the dual update