
clear all
close all
clc

%% Inizializzazione Parametri Variabili

% demand probs è un vettore lungo (maxDemand+1) (vettore delle probabilità 
% di domanda, demandProbs = ones(1,maxDemands+1)/(maxDemands+1);
% Imax è un vettore di altezza 4 (capienza massima magazzino)
% h è un vettore di altezza 4 (costo unitario magazzino)
% w è un vettore di altezza 4(penalità stockout)
% u è un vettore di altezza 4(durata set up)
% p è un vettore di altezza 4(pezzi prodotti)
% Tb è la durata di un ciclo (time bucklet)
% F è una matrice 4 x 4 con i costi del tempo di setup

Imax = [5,5,5,5]';

dm = 6;

demandProbs = 1/dm*ones(1,dm);

p=[1,2,3,4]';

u=1/2*ones(4,1);


Tb=1;

k = 1/5;

h=[1,2,3,4]';

w=[2,4,6,8]';

%STRUTTURA SETUP MAJOR-MINOR


F  =mean(h)/k.*[[0,0.5,1,1];[0.5,0,1,1];[1,1,0,0.5];[1,1,0.5,0]];

F = F - diag(diag(F));

T=4;

%% Generazione valueTable e actionTable

tic

[valueTable, actionTable, valueTensor, actionTensor] = MakePolicy...
    (Imax, demandProbs, p, u, h, w, F, T, Tb);

toc

valueTensor(1,1,1,1,1,1)

%% Simulazione Policy su singolo stato

%testiamo le politiche con una simulazione montecarlo out of sample

numScenarios=1000;

% le prime 4 componenti dello startState sono le configurazioni iniziali di
% magazzino, rispettivamente 0<=startState(i)<=Imax(i), con i = 1,2,3,4. La
% posizione 5 indica l'azione al tempo t-1 (quindi tempo 0) ed assume
% valori interi fra 1 e 12

startState = [0,0,0,0,1]';

costScenarios = SimulatePolicy(actionTensor, demandProbs, ...
p, u, h, w, F, T,Tb, numScenarios, startState)

%Confronto con la ValueTable della media dei costi ottenuti

CostoPolicy = valueTensor(startState(1)+1,startState(2)+1,startState(3)+1,startState(4)+1,startState(5),1)

costoMedio = mean(costScenarios)


%% Simulazione Policy con diversi numeri di scenari
% Queste ultime due sezioni vogliono mostrare la robustezza dell'algoritmo
%In questa si effettua un test variando il numero di scenari fra 1000 e
%10000, su combinazioni di stato random, per vedere se effettivamente il
%range di errore dell'algoritmo rimane pressochè lo stesso,plottando anche
%un grafico
i = 1;
%inizializzazione matrice costi value function-costi simulazione
Test = ones(10,2);

%inizializzazione errore relativo
erNs = zeros(10,1);

for numScenarios = 1000:1000:10000
    
    %generazione casuale startState
    
    startInventory = randi([0 length(demandProbs)-1], 1, 4);
    
    startAction = randi([1 12], 1, 1);
    
    startState = [startInventory startAction]';

    %simulazione applicazione policy
    costScenarios = SimulatePolicy(actionTensor, demandProbs, ...
        p, u, h, w, F, T,Tb, numScenarios, startState);

    Test(i,:) = [valueTensor(startState(1)+1,startState(2)+1,startState(3)+1, ...
        startState(4)+1,startState(5),1),mean(costScenarios)]
    
    erNs(i) = abs(Test(i,1) - Test(i,2))/abs(Test(i,1));
    
    i = i + 1;
    
end

plot(1000:1000:10000,erNs)

%% Calcolo errore in norma infinito
%in questa simulazione si confrontano i valori della value function e i
%costi dati dalle simulazioni, calcolati per ogni stato possibile.

numScenarios=100;

Test2=zeros(2,(Imax(1)+1)*(Imax(2)+1)*(Imax(3)+1)*(Imax(4)+1)*12);

%vettore che contiene la differenza tra valore value function e costo simulazione
er=zeros(1,(Imax(1)+1)*(Imax(2)+1)*(Imax(3)+1)*(Imax(4)+1)*12);

count = 1;

for Item1 = 0:Imax(1)
            
            for Item2 = 0:Imax(2)
                
                for Item3 = 0:Imax(3)
                    
                    for Item4 = 0:Imax(4)
                        
                        for j = 1:12

                            costScenarios = SimulatePolicy(actionTensor, demandProbs, ...
                                            p, u, h, w, F, T,Tb, numScenarios, [Item1,Item2,Item3,Item4,j]');
                        
                            Test2(:,count) = [valueTensor(Item1+1,Item2+1,Item3+1,Item4+1,j,1),mean(costScenarios)]';
                            
                            er(count) = Test2(1)-Test2(2);
                            
                            count= count+1;
                        
                        end
                        
                    end
                    
                end
                
            end
            
end

%errore assoluto in norma infinito
erInf = norm(er,Inf)

%errore relativo fratto minimo valore ottenibile
erRelInf  =norm(er,Inf)/min(Test2(1,:))

%errore relativo medio
eravg=mean(abs(er)./Test2(1,:))


