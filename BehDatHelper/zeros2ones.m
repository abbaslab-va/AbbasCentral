   function A = zeros2ones(A)
    A(A == 0) = 1;
    A(A == -2) = 1;
    A(A == -1) = 1;
   end