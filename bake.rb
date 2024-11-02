# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2024, by Samuel Williams.

# Update the project documentation with the new version number.
#
# @parameter version [String] The new version number.
def after_gem_release_version_increment(version)
	context["releases:update"].call(version)
	context["utopia:project:readme:update"].call
end
