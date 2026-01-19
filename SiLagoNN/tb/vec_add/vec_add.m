
% Memory testcase

% Features:
% Add two vectors in DPU of cells 0,0

M = [0 : 63]; 	  %! MEM<> [0,0]
A = zeros(1, 16); %! RFILE<> [0,0]
B = zeros(1, 16); %! RFILE<> [0,0]
C = zeros(1, 16); %! RFILE<> [0,0]

A(1:16) = M(1:16);
B(1:16) = M(17:32);
C = silago_dpu_add(A,B) %! DPU<> [0,0]
