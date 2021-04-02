function progenres=progen(N,M,toggleTask2)
  
      
    
    if nargin>2 && toggleTask2
%         Ub=1
%         Lb=0
%     Hi subass(eye(n)) | missing column k if agent i cant perform task k
%           Hi€R^NxKi
%           Hi=Hi(tasks, robots):1) evaluation of distances (>max)
%                                2) robot type that can perform a task
%     b= 1(vect) % siNngle task->performed by:<-->:can perform<-single agent 
%     ci= ci (tasks', robots' positions)+noise
%     Di=0
%     di=0
%     Gi=[...Gik...] | Gik=[...;1;...]
%         zi'*Gik =1=gik
%     gi= 1 vett = [...;gik;...]
c=zeros(N*N,1);
agents=spawnEntities(false,N);
tasks=spawnEntities(false,N);
        for ii=1:N %agents
    %Ki=N_In(k);
            for kk=1:N
    %         cik=distfunc(sqrt((xagent-xtask)^2+(yagent-ytask)^2));
    
            c((ii-1)*N+kk)=sqrt(sum((agents-tasks).^2,2));
    %         cik=cik+random_noise;
            end
        end
%     spawn agents

   else
    % N agents
    % ci € R^ni
    % Hi € R^S x ni
    % b € R^S
    % Pi = {zi € R^ni | Di*zi=<di, Gi*zi=gi}
    % Di € R^ ni x ni, di € R^ni
    % Gi € R^ ni x ni, gi € R^ni
    % qui:
    % ci € R^M, c € R^M*N
    % Hi € R^M x M , H € R^M x M*N
    % b € R^M
    % Pi | Gi=0, Di € R^N x N*M
    % -->
    % ni=M
    % S=M
    % ma da Gi -> ni=N ... errore?
    % 
	%clear all; close all; clc;
	%N: NUMBER OF AGENTS 
	%M: SIZE OF AGENTS' LOCAL OPTIM. VAR. 
    % ATTENTION! IT MUST STAND M>N      
        if not(M>N),error('mandatory: M>N, N first value'),end
        % % profit associated with assigning job j to machine i
        P_ = randi([10 25],N,M);
        P  = max(P_,[],'all') +1 - P_ ;

        % claim on the capacity of machine i by job j
        W = randi([5 25],N,M);
        d = zeros(N,1); % d=[...dj...]

        for ijk = 1:N 
            J_i = [];
            for jjj = 1:M
              p_j = P(:,jjj);
              [~, ind_m] = min(p_j);
              ind_ = find(ind_m == ijk);
              if ~isempty(ind_)
                J_i = [J_i jjj];
              end
            end
            c_v = zeros(N,1);
            if ~isempty(J_i)
                for lll = 1:N
                    w_l = W(lll,:);
                    for jkl=1:numel(J_i)
                        c_v(lll)=c_v(lll)+w_l(J_i(jkl));
                    end
                end
            end
            d(ijk) = 9*(M/N) + 0.4*max(c_v); 
        end

        b = ones(M,1);
        H = repmat(eye(M,M), [1,N]); % == [...Hj...] 
        % nota: la "separazione" della b sui vari agenti è arbitraria:
        % - tutta ad uno
        % - media a ciascuno
        % - whatever ...

        % machine capacity, local constraints
        D = zeros(N,M*N);% D=[...Dj...]
        for i = 1:N
            D(i,M*(i-1)+1:M*(i-1)+M) = W(i,:);
        end
         G = zeros(N,M*N);% D=[...Dj...]
        for i = 1:N
            G(i,M*(i-1)+1:M*(i-1)+M) = W(i,:);
        end
        %maximize profit
        c = reshape(P',[1,M*N]);% c=[...cj...]
        LB = zeros((N*M),1);
        UB = ones((N*M),1);

        %[zopt, fopt] = linprog(c,D,d,H,b,LB,UB)
        % min{x} c'*z | A*z=<b & Aeq*z = beq & lb=<z=<ub

        clearvars -except c D d H b LB UB zopt fopt

        progenres.b=b;progenres.c=c;progenres.d=d;progenres.D=D;
        progenres.H=H;progenres.LB=LB;progenres.UB=UB;
    end
    

end