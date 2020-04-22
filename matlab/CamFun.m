classdef CamFun
    methods(Static)
        function v = dehomo(q)
            %q = q';
            v = q(1:size(q,1)-1,:)/q(end);
        end
        
        function k = K(f, a, b, dx, dy)
            k = [f b dx; 0 a*f dy; 0 0 1];
        end
        
        function P = P(K, R, t)
            P =  K*[R t];
        end
        
        function points = projectPoints(K, R, t, Q)
            points = [];
            P =  K*[R t];
            for i=1:size(Q,1)
                hQ = [Q(i,:) 1];
                q =P*hQ';
                q = CamFun.dehomo(q);
                points = [points q];
            end
        end
        
        function points = projectPointsP(P, Q)
            points = [];
            for i=1:size(Q,1)
                hQ = [Q(i,:) 1];
                q =P*hQ';
                q = CamFun.dehomo(q);
                points = [points q];
            end
        end
        
        function ans = distortion(r, factors)
            dr = 0;
            for i=1:5;
                if length(factors) < i 
                    break;
                end
                dr = dr + factors(i)*(norm(r)^(i*2));
            end
            ans = r*[1+dr];
        end
        
        function r = R(c, b, a)
            r = [cos(a) -sin(a) 0;sin(a) cos(a) 0; 0 0 1]*[cos(b) 0 sin(b);0 1 0; -sin(b) 0 cos(b)]*[1 0 0; 0 cos(c) -sin(c); 0 sin(c) cos(c)];
        end
            
        function points = projectPointsWithDist(K,R,t,dist,Q)
            Ka = zeros(3);
            Ka(1,1) = 1;
            Ka(:,2) = [K(1,2) K(2,2)/K(1,1) 0];
            Ka(:,3) = K(:,3);
            Kb = diag([K(1,1) K(1,1) 1]);
            
            
            points = []
            P = Kb *[R t];
            for i = 1:size(Q,1)
                hQ = [Q(i,:) 1];
                q = Ka*[CamFun.distortion(CamFun.dehomo(P*hQ'), dist); 1];
                points = [points CamFun.dehomo(q)];
             end
        end
        
        function c = crossMatrix(v)
        % Returns the matrix used for cross product matrix multiplication
        % Inputs:
        %   v : the vector to be used in the cross product
            c = [0 -v(3) v(2); v(3) 0 -v(1); -v(2) v(1) 0];
        end
        
        function e = E(t, R)
             % Calculates the essential matrix 
            tx = CamFun.crossMatrix(t);
            e = tx*R;
        end
        
        % Calculates the Fundamental Matrix
        function f = F(K, R, t)
            E = CamFun.E(t,R);
            f = inv(K)'*E*inv(K);
        end
        
        % Creates a set of points along the edges of a cube, plus the 3 lines in the center of it
        function box = box3d(numberOfPoints)
            pointsInEdge = linspace(-0.5, 0.5, numberOfPoints);
            
            edge = 0.5;
            
            mm = [-0.5 0.5 ; -0.5 0.5 ; -0.5 0.5]; % column 1 is minimum, column 2 is maximum, rows are [x y z]
            [px,py,pz] = ndgrid(mm(1,:),mm(2,:),mm(3,:));
            P = [px(:) py(:) pz(:)]; % the 8 corners of a 3D P
            
            sections_per_edge = numberOfPoints-1;
            weights = ((1:sections_per_edge-1) / sections_per_edge).';
            
            edges = []; % indices into P
            points = [];
            n = size(P, 1);
            for i = 1:n-1
                pointA = P(i, :);
                for j = i+1:n
                    pointB = P(j, :);
                    if nnz(pointA - pointB) == 1
                        edges = [edges; i, j];
                        % find points along edge as weighted average of point A and B
                        points = [points; weights * pointA + (1 - weights) * pointB];
                    end
                end
            end
            
            temp = linspace(-edge, edge,  numberOfPoints);
            zeroCoords = zeros(numberOfPoints,1);
            pointsInMiddle1 = [zeroCoords temp(:) zeroCoords];
            pointsInMiddle2 = [zeroCoords  zeroCoords temp(:)];
            pointsInMiddle3 = [temp(:) zeroCoords  zeroCoords];
            
            
            points = [points; pointsInMiddle1; pointsInMiddle2; pointsInMiddle3;P];
            
            % plot corners
            plot3(P(:,1), P(:,2), P(:,3), '.r', 'markersize', 20);
            hold all
            
            % plot points along edges
            plot3(points(:,1), points(:,2), points(:,3), '.b', 'markersize', 10);
            
            
            % draw edges
            line([P(edges(:,1), 1), P(edges(:,2), 1)].', ...
                [P(edges(:,1), 2), P(edges(:,2), 2)].', ...
                [P(edges(:,1), 3), P(edges(:,2), 3)].', 'color', 'k');
            
            axis([-0.5,0.5,-0.5,0.5]);
            
            box = points;
        end
        
        function  Q = triangulate(q1, q2, K1, K2, R1, R2, t1, t2)
            P1 =  K1*[R1 t1];
            P2 =  K2*[R2 t2];
            Q = CamFun.triangulateP(q1, q2, P1, P2);
        end
        
        function  Q = triangulateP(q1, q2, P1, P2)
             B= [P1(3,:)*q1(1)-P1(1,:);
                 P1(3,:)*q1(2)-P1(2,:);
                 P2(3,:)*q2(1)-P2(1,:);
                 P2(3,:)*q2(2)-P2(2,:)];
             
             [u,s,v]=svd(B);
                Q=v(:,end);
            
         end
        
        function Q = CheckerboardPoints(N, M, l)
            Q= zeros( N*M, 3)
            for i =0:N-1
                for j =0:M-1
                    Q(i*M+j+1, 1)=i*l-((N-1)/2)*l;
                    Q(i*M+j+1, 2)=j*l-((M-1)/2)*l;
                end
            end
        end
         
        function H = EstimateHomography(q1, q2)
            x1 = q1(1)
            y1 = q1(2)
            x2 = q2(1)
            y2 = q2(2)
            
            B= [0          -x2     x2*y1   0       -y2     y2*y1   0   -1  y1;
                 x2         0       -x2*x1  y2      0       -y2*x1  1   0   -x1;
                 -x2*y1     x2*x1   0       -y2*y1  y2*x1   0       -y1 x1  0   ]
             
            [u,s,v]=svd(B);
            Hv=v(:,end);
            H= [Hv(1:3) Hv(4:6) Hv(7:9)]
        end
        
        function Hs = EstimateHomographies(Q, q)
            Hs=2
        end
        
        function  [T, q] = normalize2d(p)
            
            centroid = mean( p(1:2,:)' )'
            scale = sqrt(2) / mean( sqrt(sum(p(1:2,:).^2)) )
            
            T = diag([scale scale 1]);
            T(1:2,3) = -scale*centroid;
            
            q = T*p
            
            %{
            q = u;
            q(1:2,:) = u(1:2,:) - repmat(centroid,1,n);
            
            smallest = min(min(p))
            biggest = max(max(p))
            t = (biggest+smallest)/2;
            s = (biggest-smallest)/2;
            T = [s 0 t;
                 0 s t;
                 0 0 1]
            q = T*p
            mean(q)
            var(q)
            %}
        end
    end
end

