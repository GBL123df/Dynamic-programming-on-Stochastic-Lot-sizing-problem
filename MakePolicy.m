
% demand probs è un vettore lungo (maxDemand+1) (vettore delle probabilità 
% di domanda, demandProbs = ones(1,maxDemands+1)/(maxDemands+1);
% Imax è un vettore di altezza 4 (capienza massima magazzino)
% h è un vettore di altezza 4 (costo unitario magazzino)
% w è un vettore di altezza 4(penalità stockout)
% u è un vettore di altezza 4(durata set up)
% p è un vettore di altezza 4(pezzi prodotti)
% Tb è la durata di un ciclo (time bucklet)
% F è una matrice 4 x 4 con i costi del tempo di setup

function [valueTable, actionTable, valueTensor, actionTensor] = ...
    MakePolicy(Imax, demandProbs, p, u, h, w, F, T, Tb)

% Creazione valueTable e actionTable sia in forma matriciale che tensoriale

valueTable = zeros((Imax(1)+1) * (Imax(2)+1) * (Imax(3)+1) * (Imax(4)+1)...
    *12,T+1+5);

actionTable = zeros((Imax(1)+1) * (Imax(2)+1) * (Imax(3)+1) * (Imax(4)+1)...
    *12,T+5);

valueTensor = zeros(Imax(1)+1, Imax(2)+1, Imax(3)+1, Imax(4)+1,12, T+1);

actionTensor = zeros(Imax(1)+1, Imax(2)+1, Imax(3)+1, Imax(4)+1,12, T);

% Inizializzazione vettore di domanda

maxDemand = length(demandProbs)-1;

demandValues = (0:maxDemand);

%Inizializzazione magazzino al tempo successivo in forma tensoriale

ItnextTens = zeros(maxDemand+1,maxDemand+1,maxDemand+1,maxDemand+1,4);

% x : matrice delle possibili azioni da compiere

x = [[1,0,0,0,0,0,0,0,1]',[0,1,0,0,0,0,0,0,2]',[0,0,1,0,0,0,0,0,3]',...
    [0,0,0,1,0,0,0,0,4]',[1,0,0,0,1,0,0,0,1]',[0,1,0,0,0,1,0,0,2]',...
    [0,0,1,0,0,0,1,0,3]',[0,0,0,1,0,0,0,1,4]',[0,0,0,0,0,0,0,0,1]',...
    [0,0,0,0,0,0,0,0,2]',[0,0,0,0,0,0,0,0,3]',[0,0,0,0,0,0,0,0,4]'];

% feasible : matrice delle possibili azioni sapendo di aver compiuto una 
% specifica azione precedentemente. Serve per far rispettare i vincoli
% all'azione al tempo t, conoscendo l'azione al tempo t-1(variabile di
% stato)

feasible = [[1,0,0,0,0,1,1,1,1,0,0,0];[0,1,0,0,1,0,1,1,0,1,0,0];...
    [0,0,1,0,1,1,0,1,0,0,1,0];[0,0,0,1,1,1,1,0,0,0,0,1];...
    [1,0,0,0,0,1,1,1,1,0,0,0];[0,1,0,0,1,0,1,1,0,1,0,0];...
    [0,0,1,0,1,1,0,1,0,0,1,0];[0,0,0,1,1,1,1,0,0,0,0,1];...
    [1,0,0,0,0,1,1,1,1,0,0,0];[0,1,0,0,1,0,1,1,0,1,0,0];...
    [0,0,1,0,1,1,0,1,0,0,1,0];[0,0,0,1,1,1,1,0,0,0,0,1]];

% Iniziallizzazione magazzino

It = zeros(4,length(demandValues));

Itnext = It;

% Inserimento possibili combinazioni magazzini e azione al tempo precedente 
%nelle ultime 5 colonne, ci indicano lo stato del magazzino alla riga count

count = 1;

for Item1 = 0:Imax(1)
            
    for Item2 = 0:Imax(2)
                
        for Item3 = 0:Imax(3)
                    
            for Item4 = 0:Imax(4)
                        
                for lambda = 1:12
                        
                    valueTable(count,T+2:T+6) = [Item1, Item2, ...
                        Item3, Item4,lambda];
                        
                    actionTable(count,T+1:T+5) = [Item1, Item2, ...
                        Item3, Item4,lambda];
                        
                    count = count + 1;
                        
                 end
                        
             end
                    
        end
                
    end
            
end

% Algoritmo principale

for t = (T-1):-1:0
    
    count = 1;
    
    % Variamo le configurazioni di magazzino possbili
        
    for Item1 = 0:Imax(1)

        for Item2 = 0:Imax(2)
                
            for Item3 = 0:Imax(3)

                for Item4 = 0:Imax(4)

                    % Scorriamo tutte le azioni ponendole come quelle
                    % dalle quali proveniamo in modo cronologico
                        
                    for lambda = 1:12

                        % Inizzializziamo le variabili
                            
                        Value = Inf;
                            
                        minCost = Inf;
    
                        bestAction = NaN;
                            
                        % Salviamo la configurazione di magazzino
                        
                        It = [Item1,Item2,Item3,Item4]';
                            
                        % Salviamo l'azione che stiamo analizzando
                            
                        xprec=x(:,lambda);
                            
                        for i = 1:12

                            % Cerchiamo la migliore azione i sapendo di
                            % aver compiuto precedentemente l'azione j
                                
                            % Verifica del rispetto dei vincoli di
                            % capacità del magazzino e se l'azione i è
                            % possibile sapendo di aver compiuto 
                            % precedentemente l'azione j 

                            if It(1) + p(1)*x(1,i)*(1-u(1)*x(5,i)/ ...
                                    Tb)<=Imax(1) && It(2) + p(2)* ...
                                    x(2,i)*(1-u(2)*x(6,i)/Tb) ...
                                    <=Imax(2) && It(3) + p(3)*x(3,i) ...
                                    *(1-u(3)*x(7,i)/Tb)<=Imax(3) ...
                                    && It(4) + p(4)*x(4,i)*(1-u(4)* ...
                                    x(8,i)/Tb)<=Imax(4) && ...
                                    feasible(lambda,i) == 1

                                % Calcolo nuovo stato del magazzino per
                                % ogni domanda ricevuta
                                    
                                Itnext(1,:) = floor(Item1 + p(1) ...
                                    *x(1,i)*(1-u(1)*x(5,i)/Tb))- ...
                                    demandValues;

                                Itnext(2,:) = floor(Item2 + p(2) ...
                                    *x(2,i)*(1-u(2)*x(6,i)/Tb))- ...
                                    demandValues;

                                Itnext(3,:) = floor(Item3 + p(3) ...
                                    *x(3,i)*(1-u(3)*x(7,i)/Tb))- ...
                                    demandValues;

                                Itnext(4,:) = floor(Item4 + p(4) ...
                                    *x(4,i)*(1-u(4)*x(8,i)/Tb))- ...
                                    demandValues;
                                
                                % Salvataggio degli stati del magazzino in
                                % forma tensoriale per ogni domanda d1,d2
                                % d3,d4 e item k
                                % Questo perchè noi sappiamo che la domanda
                                % per un prodotto può essere diversa da
                                % quella per gli altri prodotti
                                % nell'intervallo t+1, quindi qui andiamo
                                % a cercare tutti i possibili scenari, che
                                % vanno richiusi in una matrice
                                % 5-dimensionale (5 è il numero di 
                                %componenti di una configurazione di stato.
                                
                                for d1 = 1:maxDemand+1

                                    for d2 = 1:maxDemand+1

                                        for d3 = 1:maxDemand+1

                                            for d4 = 1:maxDemand+1

                                                for k = 1:4

                                                    % Itnext potrebbe
                                                    % assumere valori
                                                    % negativi quando non 
                                                    % soddisfiamo la domanda, 
                                                    % ItnextTens serve per
                                                    % salvare con quale
                                                    % configurazione di
                                                    % domanda e per quale
                                                    % item abbiamo il
                                                    % magazzino negativo
                                                    % per poi essere usato
                                                    % per compiere il
                                                    % calcolo delle
                                                    % penalità
                                                    
                                                    if k == 1
                                                        
                                                        ItnextTens(d1,...
                                                            d2,d3,d4,k) ...
                                                            = -min( ...
                                                            Itnext(k,d1),0);
                                                        
                                                    elseif k == 2
                                                        
                                                        ItnextTens(d1,...
                                                            d2,d3,d4,k) ...
                                                            = -min( ...
                                                            Itnext(k,d2),0);
                                                        
                                                    elseif k == 3
                                                        ItnextTens(d1,...
                                                            d2,d3,d4,k) ...
                                                            = -min( ...
                                                            Itnext(k,d3),0);
                                                        
                                                    else
                                                        
                                                        ItnextTens(d1,...
                                                            d2,d3,d4,k) ...
                                                            = -min( ...
                                                            Itnext(k,d4),0);
                                                    end
                                                    
                                                end
                                                
                                            end
                                            
                                        end
                                        
                                    end
                                    
                                end
                                
                                % Calcoliamo la value function al tempo t+1
                                % per gli stati di magazzino calcolati
                                % precedentemente, ponendo magazzino uguale a 0 nel 
                                % caso in cui la domanda non è stata 
                                % soddisfatta 
                                 
                                ValueTensNext = valueTensor(max ...
                                (Itnext(1,:),0)+1,max(Itnext(2,:),0)+1, ...
                                max(Itnext(3,:),0)+1,max(Itnext(4,:),0) ...
                                +1,lambda,t+2);
                            
                                
                                % Calcolo valore atteso value function
                                %(effettuo prodotti tra vettori e matrici
                                %in 4 dimensioni per calcolare il valore
                                %atteso rispetto alle 4 combinazioni di
                                %magazzino
                                
                                ExpValNext =demandProbs*squeeze( ...
                                    pagemtimes(pagemtimes(demandProbs, ...
                                    ValueTensNext),demandProbs')) ...
                                    *demandProbs';
                                
                                % Calcolo costi di setup
                                
                                SetupCost = F(xprec(9),x(9,i))*max(x(5:8,i));
                                
                                % Calcolo costo di giacenza(esso è
                                % calcolato rispetto al magazzino al tempo
                                % t)
                                
                                InvCost = h'*(It.*(It > 0));
                                
                                % Calcolo penalità per la domanda non
                                % soddisfatta
                                
                                Penality = demandProbs*squeeze( ...
                                    pagemtimes(demandProbs,squeeze( ...
                                    pagemtimes(pagemtimes(demandProbs, ...
                                    ItnextTens),demandProbs'))))*w;
                                
                                % Calcolo value function al tempo t

                                Value = InvCost + SetupCost + Penality ...
                                    + ExpValNext;
                                
                            end
                            
                            % Verifica che l'azione i sia la migliore
                            % tramite il valore della value function
                            % calcolata

                            if Value < minCost

                                    minCost = Value;

                                    bestAction = i;

                            end
                            
                        end
                        
                        % Salviamo i valori ottenuti
                        
                        valueTable(count,t+1) = minCost;
                        
                        valueTensor(Item1+1,Item2+1,Item3+1,Item4+1,lambda, ...
                            t+1) = minCost;
        
                        actionTable(count,t+1) = bestAction;
                        
                        actionTensor(Item1+1,Item2+1,Item3+1,Item4+1,lambda, ...
                            t+1) = bestAction;
                        
                        count = count + 1;

                    end
                    
                end
                
            end
            
        end
        
    end

end %fine cicli di iterazione su tempo e configurazioni di stato
    