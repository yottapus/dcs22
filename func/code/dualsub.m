function...
    [primCost,dualCost,primRA,dualRA,...consErr,
                lam,ZZ,ZRA,MAXITERS]=...
                           dualsub(NN,nni,AA,AANW,bb,cc,dd,DD,HH,LBB,UBB)

    %linprog options
    lpoptions = optimoptions('linprog','Display','none');
    
    % % printing init
    msglnt=0;
    
    MAXITERS =5e2;
    fprintf('iterations: %d  \n',MAXITERS);

    fprintf('initializing...\n');
    primCost=zeros(MAXITERS,1); % cost € R
    dualCost=zeros(MAXITERS,1);
    primRA=zeros(MAXITERS,1);
    dualRA=zeros(MAXITERS,1);
%     consErr=zeros(MAXITERS,1);
    
    % agents init
    % agent zi € R^ni, zz=[...;zi;...] agent matrix € R^N x ni
    ZZ=zeros(NN,nni,MAXITERS); 
    ZRA=zeros(NN,nni,MAXITERS);
    
    SS=nni;
    % when %==SS is displayed, means that it's our particular case nni==SS
    
    %multiplier init
    lam=zeros(NN,SS,MAXITERS);% 
    vv=zeros(NN,SS); % vv=[...;vi;...], vi€ R ^ SS
    
    % b splitting
    bi=bb/NN;
    
    for tt = 1:MAXITERS-1
        % todo
        if mod(tt,MAXITERS/100)==0
            msglnt=fprintf('progress: %d%%\n',tt*100/MAXITERS);
        end
        
        %stepsize
        alpha_t = 1.6*(1/tt)^0.65; % 1/tt^alpha with alpha in (0.5, 1]
%         aa=0.1;%bb=0.1;% a,b>0
%         alpha_t=aa/(bb+tt);%square summable, not summable s.size
        
        
        % vm_i^t+1= sum{j € N_i} (a_ij*mu_j^t)
	%		vl_i^t+1= sum{j € N_i} (a_ij*la_j^t)
            % vi =  sum_{k:1:N} aik*muk^t
        

        for ii=1:NN
            N_ii = find(AANW(:,ii) == 1)';% neigh(i)
            for kk=1:SS 
                
                % update: averaging
                % vvi =  sum_{k:1:N} aik*lam_k^t
                vv(ii,kk) = AA(ii,ii)*lam(ii,kk,tt);

                for jj = N_ii
                    vv(ii,kk) = vv(ii,kk) + AA(ii,jj)*lam(jj,kk,tt);
                end
            end
        end

        for ii=1:NN
            
            ci=cc((ii-1)*nni+1 : ii*nni);
            Hi=HH(:,nni*(ii-1)+1:nni*ii);
            UBi=UBB((ii-1)*nni+1:ii*nni);
            LBi=LBB((ii-1)*nni+1:ii*nni);
            Di=DD(ii,SS*(ii-1)+1:SS*ii);
            
            
            [ZZ(ii,:,tt),~,~]=linprog(ci+(vv(ii,:))*Hi', Di,dd(ii),...
            [],[],LBi,UBi,lpoptions);
            

            if tt==1
                ZRA(ii,:,tt) = ZZ(ii,:,tt);
            else
                ZRA(ii,:,tt) = (1/tt)*((tt-1)*ZRA(ii,:,tt-1)...
                                                  +ZZ(ii,:,tt));
            end

        end

        for ii=1:NN
            
            Hi=HH(:,nni*(ii-1)+1:nni*ii);
            
            grad_ii=Hi*ZZ(ii,:,tt)'-bi;
            lam(ii,:,tt+1)=vv(ii,:)'+alpha_t*grad_ii;

        end


        for ii=1:NN
            ci=cc((ii-1)*nni+1 : ii*nni);
            
            ffii = ci * ZZ(ii,:,tt)';
            primCost(tt) = primCost(tt) + ffii;
            %
            ffii = ci * ZRA(ii,:,tt)';
            primRA(tt) = primRA(tt) + ffii;
            %
            qqi = ci * ZZ(ii,:,tt)'...
                +lam(ii,:,tt) * ( ZZ(ii,:,tt) - bi' )';
            dualCost(tt) = dualCost(tt) + qqi;
            %
            qqi = ci *ZRA(ii,:,tt)'...
                + lam(ii,:,tt) * ( ZRA(ii,:,tt) - bi' )';
            dualRA(tt) = dualRA(tt) + qqi;
                
%             consErr(tt) = consErr(tt) + norm(lam(ii,tt) - lamAvg);

        end
        if mod(tt-99,MAXITERS/100)==0
            fprintf((repmat('\b', 1,msglnt)));
        end
        
    end
    
    tt=MAXITERS;
    fprintf((repmat('\b', 1,msglnt)));
    fprintf('progress: %d%%\n',100);
    
    for ii=1:NN
        for kk=1:SS
            N_ii = find(AANW(:,ii) == 1)';

            vv(ii,kk) = AA(ii,ii)*lam(ii,kk,tt);

            for jj = N_ii
            	vv(ii,kk) = vv(ii,kk) + AA(ii,jj)*lam(jj,kk,tt);
            end
        end
    end
    
  
    for ii=1:NN
        
        ci=cc((ii-1)*nni+1 : ii*nni);
        Hi=HH(:,nni*(ii-1)+1:nni*ii);
        UBi=UBB((ii-1)*nni+1:ii*nni);
        LBi=LBB((ii-1)*nni+1:ii*nni);
        Di=DD(ii,SS*(ii-1)+1:SS*ii);
            
  
        [ZZ(ii,:,tt),~,~]=linprog(ci+(vv(ii,:))*Hi',Di,dd(ii),...
            [],[],LBi,UBi,lpoptions);
        if tt==1
            ZRA(ii,:,tt) = ZZ(ii,:,tt);
        else
            ZRA(ii,:,tt) = (1/tt)*((tt-1)*ZRA(ii,:,tt-1)...
                                             +ZZ(ii,:,tt));
        end
        
        ffii = ci * ZZ(ii,:,tt)';
        primCost(tt) = primCost(tt) + ffii;
        %
        ffii = ci * ZRA(ii,:,tt)';
        primRA(tt) = primRA(tt) + ffii;
        %
        qqi = ci * ZZ(ii,:,tt)'...
            +lam(ii,:,tt) * ( ZZ(ii,:,tt) - bi' )';
        dualCost(tt) = dualCost(tt) + qqi;
        %
        qqi = ci *ZRA(ii,:,tt)'...
            + lam(ii,:,tt) * ( ZRA(ii,:,tt) - bi' )';
        dualRA(tt) = dualRA(tt) + qqi;
            
%        consErr(tt) = consErr(tt) + norm(lam(ii,tt) - lamAvg);
    end
    
     
end    