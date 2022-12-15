
% demand probs è un vettore lungo (maxDemand+1) (vettore delle probabilità 
% di domanda, demandProbs = ones(1,maxDemands+1)/(maxDemands+1);
% Imax è un vettore di altezza 4 (capienza massima magazzino)
% h è un vettore di altezza 4 (costo unitario magazzino)
% w è un vettore di altezza 4(penalità stockout)
% u è un vettore di altezza 4(durata set up)
% p è un vettore di altezza 4(pezzi prodotti)
% Tb è la durata di un ciclo (time bucklet)
% F è una matrice 4 x 4 con i costi del tempo di setup
% actionTensor è il tensore delle azioni ottimali per le coppie stato 
% (5 componenti)-tempo
% numScenarios numero di simulazioni
% startState stato iniziale da cui faccio partire il calcolo del costo

function costScenarios = SimulatePolicy(actionTensor, demandProbs, ...
p, u, h, w, F, T,Tb, numScenarios, startState)

% x : matrice delle possibili azioni da compiere

x = [[1,0,0,0,0,0,0,0,1]',[0,1,0,0,0,0,0,0,2]',[0,0,1,0,0,0,0,0,3]',...
    [0,0,0,1,0,0,0,0,4]',[1,0,0,0,1,0,0,0,1]',[0,1,0,0,0,1,0,0,2]',...
    [0,0,1,0,0,0,1,0,3]',[0,0,0,1,0,0,0,1,4]',[0,0,0,0,0,0,0,0,1]',...
    [0,0,0,0,0,0,0,0,2]',[0,0,0,0,0,0,0,0,3]',[0,0,0,0,0,0,0,0,4]'];

% Creazione distribuzione multinomiale basata sulle probabilità
% demandProbs

pd = makedist('Multinomial','probabilities',demandProbs);

% Creazione matrice in 3D dove abbiamo delle possibili configurazioni di
% domanda per ogni item e in ogni instante di tempo rispetto alla 
% distribuzione creata precedentemente 

demandScenarios = random(pd,numScenarios,4,T)-1;

% Creazione vettore colonna per salvataggio del costo delle politiche 
% applicate nello scenario simulato

costScenarios = zeros(numScenarios,1);

% Algoritmo principale

for k = 1:numScenarios
    
    % Inizializzazione stato iniziale per ogni scenario
    
    state = startState;

    cost = 0;

    for t = 1:T
        
        % Salviamo lo stato su cui ci troviamo
        
        xprec=x(:,state(5));
        
        % Salviamo l'indice della migliore azione individuata
        % dall'algoritmo MakePolicy
        
        actionIndex = actionTensor(state(1)+1,state(2)+1,state(3)+1,...
            state(4)+1,state(5), t); 
        
        % Calcolo costi di setup e di giacenza
        
        SetupCost = F(xprec(9),x(9,actionIndex))*max(x(5:8,actionIndex)); 
        
        InvCost = h'*(state(1:4).*(state(1:4) > 0));
        
        % Calcolo nuovo stato di magazzino
        
        state(1) = floor(state(1) + p(1)*x(1,actionIndex)*(1-u(1)* ...
            x(5,actionIndex)/Tb))- demandScenarios(k,1,t);
        
        state(2) = floor(state(2) + p(2)*x(2,actionIndex)*(1-u(2)* ...
            x(6,actionIndex)/Tb))- demandScenarios(k,2,t);
        
        state(3) = floor(state(3) + p(3)*x(3,actionIndex)*(1-u(3)* ...
            x(7,actionIndex)/Tb))- demandScenarios(k,3,t);
        
        state(4) = floor(state(4) + p(4)*x(4,actionIndex)*(1-u(4)* ...
            x(8,actionIndex)/Tb))- demandScenarios(k,4,t);
        
        % Calcolo penalità per domande non soddisfatte
        
        Penality = -min(0,state(1:4))'*w;
        
        % Calcolo costo totale
        
        cost = cost + SetupCost + InvCost + Penality;
        
        % Salvataggio del nuovo stato di magazzino sostituendo i possibili
        % valori negativi (dovuti a domande non soddisfatte) con il valore
        % 0 e dell'indice della migliore azione individuata precedentemente
        
        state(1:4) = max(0,state(1:4));
        
        state(5) = actionIndex;

    end
    
    % Salvataggio costo dello scenario
    
    costScenarios(k) = cost;

end