function H2to1 = ComputeHNorm(p1, p2)
[row,col] = size(p2); 
L = [0]; z13 = [0,0,0];
p2 = [p2;ones(1,col)];
p1 = [p1;ones(1,col)];
t1 = norm_matrix(p2);
t2 = norm_matrix(p1);
p2 = t1*p2; 
p1 = t2*p1;

L = [p2(:,1).', z13, p1(1,1)*(-1)*(p2(:,1).');
     z13, p2(:,1).', p1(2,1)*(-1)*(p2(:,1).')];
for i=2:col
    L = [L;
         p2(:,i).', z13, p1(1,i)*(-1)*(p2(:,i).');
         z13, p2(:,i).', p1(2,i)*(-1)*(p2(:,i).')];
end

a = (L.')*L;
[v,d] = eig(a);

min = d(9,9);
index = 0;
for i=1:9
    if (d(i,i)~=0) & (d(i,i)<min)
        min = d(i,i);
        index = i;
    end
end

x = v(:,index).';

Hnorm = [x(1),x(2),x(3);x(4),x(5),x(6);x(7),x(8),x(9)];
H2to1 = inv(t2)*Hnorm*t1;%turn "normalized H" back to H
end

function Tnorm = norm_matrix(p2)
[row,col] = size(p2); %row=2, col=n
avg = sum(p2,2)/col;
totaldist = 0;
for i=1:col
    totaldist = totaldist + pdist([avg(1),avg(2); p2(1,i),p2(2,i)]);
end
k = 1/(totaldist/(col*sqrt(2))); 
Ttran =  [1 0 -avg(1);0 1 -avg(2);0 0 1];
Tscale = [k 0 0;0 k 0;0 0 1];
Tnorm = Tscale*Ttran;
end