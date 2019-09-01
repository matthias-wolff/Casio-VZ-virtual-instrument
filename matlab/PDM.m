syms x x0 a b y real;

eqns = [ a*x0 == 0.5, 1==b*(1-x0)+0.5, y==b*(x-x0)+0.5 ];
S = solve(eqns,[x0,b,y]);
simplify(S.x0); fprintf('x0 = '); disp(S.x0);
simplify(S.b);  fprintf('b  = '); disp(S.b );
simplify(S.y);  fprintf('y  = b*(x-x0)+0.5 = '); disp(S.y );

syms phi real;
assume(a>=1);

for i = 135:5:180
  phi = i/180*pi;
  S2 = solve(phi==pi-atan(a)+atan(S.b), a);
  fprintf('phi = %d° -> a = %g = ',i,eval(S2));
  disp(S2);
end

% syms alpha;
% u = [1;a];
% v = [1;S.b];
% cosa = u'*v/(sqrt(u'*u)+sqrt(v'*v))
% solve(cosa==cos(alpha),a)