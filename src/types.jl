"""
An abstract type that serves as a parent type for all generator types in the system.
This type is used to define a common interface for different kinds of generators.
"""
abstract type AbstractGenerator end

"""
An abstract type that serves as a base for all dual generator types in the system.
This type is intended to be extended by concrete implementations of dual generators.
"""
abstract type AbstractDualGenerator end

"""
Abstract type representing a generic trial.
This serves as a base type for different kinds of trials in the system.
"""
abstract type AbstractTrial end
