R= [sqrt(0.5), -sqrt(0.5), 0;
    sqrt(0.5), sqrt(0.5),  0;
    0, 0, 1];

t=[0; 0; 10];

K= CamFun.K(1000, 1, 0, 1080/2, 1920/2)

P = CamFun.P(K, R, t)

Q =[];

for i =0:1
  for j =0:1
      for k =0:1
          Q=[Q; i,j,k];
      end
  end
end

q = CamFun.projectPointsP(P,Q)

C = CamFun.CheckerboardPoints(5,5,1)
plot3(C(:,1), C(:,2), C(:,3), '.b', 'markersize', 10);


%EX 05.D
Q = transpose(CamFun.CheckerboardPoints(10,20,1));

Q_a = transpose(CamFun.R(pi/10,0,0)*Q) ;
Q_b = transpose(CamFun.R(0,0,0)*Q) ;
Q_c = transpose(CamFun.R(-pi/10,0,0)*Q) ;

plot3(Q_a(:,1), Q_a(:,2), Q_a(:,3), '.b', 'markersize', 10);
hold on
plot3(Q_b(:,1), Q_b(:,2), Q_b(:,3), '.b', 'markersize', 10);

plot3(Q_c(:,1), Q_c(:,2), Q_c(:,3), '.b', 'markersize', 10);
hold off