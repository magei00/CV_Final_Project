K1= eye(3);
K2= eye(3);
R1= eye(3);
R2= eye(3);
t1= [0;0;0];
t2= [-5;0;2];

Qa =[2,4,10];
Qb =[2,4,20];

CamFun.projectPoints(K1, R1, t1, Qa)

CamFun.projectPoints(K1, R1, t1, Qb)

CamFun.projectPoints(K2, R2, t2, Qa)

CamFun.projectPoints(K2, R2, t2, Qb)

%EX4.C
q1c = [-1/6, 1/3, 1];
q2c = [-1/2, 2/7, 1];

C = CamFun.triangulate(q1c, q2c, K1, K2, R1, R2, t1, t2 );
C = CamFun.dehomo(C)

%EX4.D
err = [0.1,0.1,0];
q11c= q1c+err;
q22c= q2c+err;

Qerr = CamFun.triangulate(q11c, q22c, K1, K2, R1, R2, t1, t2 );
Qerr = transpose(CamFun.dehomo(Qerr))
K1err = CamFun.projectPoints(K1, R1, t1, Qerr)

K2err = CamFun.projectPoints(K2, R2, t2, Qerr)

%EX04.E

Q= [];
for i =0:2
    for j =0:2
        for k =0:2
            Q = [Q [i; j ; 10+10*k]];
        end
    end
end

f = CamFun.F(K2, R2, t2)

%Ex05.H
QH = []
for i =0:2
    for j =0:2
        for k =0:2
            QH = [QH [i; j ; 10]];
        end
    end
end

H = CamFun.EstimateHomography(QH(1,:), QH(2,:))

%EC04.I
q1c = [-1/6; 1/3; 1];
q2c = [-1/2; 2/7; 1];
p =[q1c q2c]
T = CamFun.normalize2d(p)
