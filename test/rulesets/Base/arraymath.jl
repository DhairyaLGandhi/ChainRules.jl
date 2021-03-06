@testset "arraymath" begin
    @testset "inv(::Matrix{$T})" for T in (Float64, ComplexF64)
        B = generate_well_conditioned_matrix(T, 3)
        test_frule(inv, B)
        test_rrule(inv, B)
    end

    @testset "*: $T" for T in (Float64, ComplexF64)
        ⋆(a) = round.(5*randn(T, a))  # Helper to generate nice random values
        ⋆(a, b) = ⋆((a, b))  # matrix
        ⋆() = only(⋆(()))  # scalar

        @testset "Scalar-Array $dims" for dims in ((3,), (5,4), (2, 3, 4, 5))
            test_rrule(*, ⋆(), ⋆(dims))
            test_rrule(*, ⋆(dims), ⋆())
        end

        @testset "AbstractMatrix-AbstractVector n=$n, m=$m" for n in (2, 3), m in (4, 5)
            @testset "Array" begin
                test_rrule(*, n ⋆ m, ⋆(m))
            end
        end

        @testset "AbstractVector-AbstractMatrix n=$n, m=$m" for n in (2, 3), m in (4, 5)
            @testset "Array" begin
                test_rrule(*, ⋆(n), 1 ⋆ m)
            end
        end

        @testset "AbstractMatrix-AbstractMatrix" begin
            @testset "Matrix * Matrix n=$n, m=$m, p=$p" for n in (2, 5), m in (2, 4), p in (2, 3)
                @testset "Array" begin
                    test_rrule(*, (n⋆m), (m⋆p))
                end

                @testset "SubArray - $indexname" for (indexname, m_index) in (
                    ("fast", :), ("slow", m:-1:1)
                )
                    test_rrule(*, view(n⋆m, :, m_index), view(m⋆p, m_index, :))
                    test_rrule(*, n⋆m, view(m⋆p, m_index, :))
                    test_rrule(*, view(n⋆m, :, m_index), m⋆p)
                end

                @testset "Adjoints and Transposes" begin
                    test_rrule(*, Transpose(m⋆n) ⊢ Transpose(m⋆n), Transpose(p⋆m) ⊢ Transpose(p⋆m))
                    test_rrule(*, Adjoint(m⋆n) ⊢ Adjoint(m⋆n), Adjoint(p⋆m) ⊢ Adjoint(p⋆m))

                    test_rrule(*, Transpose(m⋆n) ⊢ Transpose(m⋆n), (m⋆p))
                    test_rrule(*, Adjoint(m⋆n) ⊢ Adjoint(m⋆n), (m⋆p))

                    test_rrule(*, (n⋆m), Transpose(p⋆m) ⊢ Transpose(p⋆m))
                    test_rrule(*, (n⋆m), Adjoint(p⋆m) ⊢ Adjoint(p⋆m))
                end
            end
        end

        @testset "Covector * Vector n=$n" for n in (3, 5)
            @testset "$f" for f in (adjoint, transpose)
                # This should be same as dot product and give a scalar
                test_rrule(*, f(⋆(n)) ⊢ f(⋆(n)), ⋆(n))
            end
        end
    end


    @testset "$f" for f in (/, \)
        @testset "Matrix" begin
            for n in 3:5, m in 3:5
                A = randn(m, n)
                B = randn(m, n)
                test_rrule(f, A, B)
            end
        end
        @testset "Vector" begin
            x = randn(10)
            y = randn(10)
            test_rrule(f, x, y)
        end
        if f == (\)
            @testset "Matrix $f Vector" begin
                X = randn(10, 4)
                y = randn(10)
                test_rrule(f, X, y)
            end
            @testset "Vector $f Matrix" begin
                x = randn(10)
                Y = randn(10, 4)
                test_rrule(f, x, Y; output_tangent=Transpose(rand(4)))
            end
        end
    end
    @testset "/ and \\ Scalar-AbstractArray" begin
        A = randn(3, 4, 5)
        test_rrule(/, A, 7.2)
        test_rrule(\, 7.2, A)
    end


    @testset "negation" begin
        A = randn(4, 4)
        Ā = randn(4, 4)

        test_rrule(-, A)
        test_rrule(-, Diagonal(A); output_tangent=Diagonal(Ā))
    end
end
