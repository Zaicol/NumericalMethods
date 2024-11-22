#ifndef JACOBI_SOLVER_C_H
#define JACOBI_SOLVER_C_H

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
    double* xNext;  // Pointer to result array
    int n;          // Size of the array
    double residualNorm;
    double norm;
} Result;

// Function declaration for solving Jacobi
Result solveJacobi(double** A, double* b, int n, double tol, int maxIterations);

void freeResult(Result* result);

#ifdef __cplusplus
}
#endif

#endif // JACOBI_SOLVER_C_H
