#!/bin/bash

# CoastSat Shoreline Publication - Version Comparison Examples
# This file shows different ways to configure interface.crate versions for comparison

echo "🏖️ CoastSat Shoreline Publication Version Comparison Examples"
echo "=============================================================="
echo ""

# Example 1: Default comparison (latest vs July 2025 release)
echo "📌 Example 1: Default comparison"
echo "Command: ./scripts/publish_to_docs.sh nzd0021"
echo "Result: Compares 'latest' vs 'interface.crate-d61c2052a-20250725024714'"
echo ""

# Example 2: Specify all versions via command line
echo "📌 Example 2: Custom versions via command line"
echo "Command: ./scripts/publish_to_docs.sh nzd0021 latest latest interface.crate-cb67e8e26-20250801011405"
echo "Result: Main publication uses 'latest', compares 'latest' vs 'interface.crate-cb67e8e26-20250801011405'"
echo ""

# Example 3: Use environment variables
echo "📌 Example 3: Environment variables override"
echo "Command: COMPARISON_V1=interface.crate-cb67e8e26-20250801011405 COMPARISON_V2=interface.crate-d61c2052a-20250725024714 ./scripts/publish_to_docs.sh nzd0021"
echo "Result: Compares August 2025 release vs July 2025 release"
echo ""

# Example 4: Different site with specific versions
echo "📌 Example 4: Australian site with specific versions"
echo "Command: ./scripts/publish_to_docs.sh aus0001 interface.crate-cb67e8e26-20250801011405 latest interface.crate-d61c2052a-20250725024714"
echo "Result: Australian site, main uses August release, compares 'latest' vs July release"
echo ""

# Example 5: Same versions will default the second one
echo "📌 Example 5: Providing only 3 arguments"
echo "Command: ./scripts/publish_to_docs.sh nzd0001 latest interface.crate-cb67e8e26-20250801011405"
echo "Result: Main uses 'latest', compares 'interface.crate-cb67e8e26-20250801011405' vs 'interface.crate-d61c2052a-20250725024714' (default)"
echo ""

echo "🔍 Available Interface.crate Versions:"
echo "  • latest                                    (most recent GitHub release)"
echo "  • interface.crate-cb67e8e26-20250801011405  (August 1, 2025 release)"
echo "  • interface.crate-d61c2052a-20250725024714  (July 25, 2025 release)"
echo ""
echo "💡 Tips:"
echo "  • Use 'latest' for the most current version"
echo "  • Use specific versions for reproducible comparisons"
echo "  • Environment variables override command line arguments"
echo "  • The comparison page will show side-by-side differences"
echo ""
echo "🌐 After running, view the comparison at:"
echo "  docs/version-comparison.html"
