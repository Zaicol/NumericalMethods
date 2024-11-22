#include "JacobiSolver_c.h"
#include <cmath>
#include <stdexcept>
#include <vector>
#include <cstdlib>

// Helper function to dynamically allocate a 2D array
double** allocate2DArray(int rows, int cols) {
    double** array = (double**)malloc(rows * sizeof(double*));
    for (int i = 0; i < rows; ++i) {
        array[i] = (double*)malloc(cols * sizeof(double));
    }
    return array;
}

// Helper function to free a 2D array
void free2DArray(double** array, int rows) {
    for (int i = 0; i < rows; ++i) {
        free(array[i]);
    }
    free(array);
}

void freeResult(Result* result) {
    if (result->xNext != nullptr) {
        free(result->xNext);
        result->xNext = nullptr;
    }
}

// Jacobi solver implementation
Result solveJacobi(double** A, double* b, int n, double tol, int maxIterations) {
    if (n <= 0 || tol <= 0 || maxIterations <= 0) {
        throw std::invalid_argument("Invalid input parameters.");
    }

    // Initialize x and xNext
    std::vector<double> x(n, 0.0);
    std::vector<double> xNext(n, 0.0);

    // Iterative Jacobi process
    for (int k = 0; k < maxIterations; ++k) {
        for (int i = 0; i < n; ++i) {
            double sum = 0.0;
            for (int j = 0; j < n; ++j) {
                if (i != j) {
                    sum += A[i][j] * x[j];
                }
            }
            xNext[i] = (b[i] - sum) / A[i][i];
        }

        // Calculate the infinity norm of the difference
        double norm = 0.0;
        for (int i = 0; i < n; ++i) {
            norm = std::max(norm, std::fabs(xNext[i] - x[i]));
        }

        // Check for convergence
        if (norm < tol) {
            // Calculate residual and residualNorm
            std::vector<double> residual(n, 0.0);
            for (int i = 0; i < n; ++i) {
                double sum = 0.0;
                for (int j = 0; j < n; ++j) {
                    sum += A[i][j] * xNext[j];
                }
                residual[i] = sum - b[i];
            }

            double residualNorm = 0.0;
            for (double r : residual) {
                residualNorm += r * r;
            }
            residualNorm = std::sqrt(residualNorm);

            // Allocate result dynamically
            double* resultXNext = (double*)malloc(n * sizeof(double));
            for (int i = 0; i < n; ++i) {
                resultXNext[i] = xNext[i];
            }

            return {resultXNext, n, residualNorm, norm};
        }

        // Update x
        x = xNext;
    }

    throw std::runtime_error("Jacobi method did not converge within the maximum number of iterations.");
}
