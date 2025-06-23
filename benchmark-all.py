#!/usr/bin/env python3
"""
Comprehensive benchmark comparing all implementations:
- Objective-C
- Swift (async/await)
- Swift (GCD optimized)
- Swift (Ultra-optimized with NSString)
"""

import subprocess
import time
import os
import statistics
import json
from pathlib import Path
import sys

class ComprehensiveBenchmark:
    def __init__(self):
        self.objc_binary = "./pdf22md"
        self.swift_binary = "./swift/.build/release/pdf22md-swift"
        self.test_pdfs = [
            ("small", "test/small.pdf", 5),
            ("medium", "test/medium.pdf", 50),
            ("large", "test/large.pdf", 200),
        ]
        
    def build_implementations(self):
        """Build all implementations"""
        print("Building all implementations...")
        result = subprocess.run(["./build.sh", "--clean"], capture_output=True, text=True)
        if result.returncode != 0:
            print(f"Build failed: {result.stderr}")
            sys.exit(1)
        print("Build completed successfully\n")
        
    def run_single_benchmark(self, binary, pdf_path, output_path, assets_path, flags=[]):
        """Run a single benchmark and return timing"""
        # Clean up previous outputs
        for path in [output_path, assets_path]:
            if os.path.exists(path):
                if os.path.isdir(path):
                    subprocess.run(["rm", "-rf", path])
                else:
                    os.remove(path)
        
        # Build command
        cmd = [binary, "-i", pdf_path, "-o", output_path, "-a", assets_path, "-d", "144"] + flags
        
        # Measure execution time
        start_time = time.perf_counter()
        process = subprocess.run(cmd, capture_output=True, text=True)
        end_time = time.perf_counter()
        
        if process.returncode != 0:
            print(f"Error running {' '.join(cmd)}: {process.stderr}")
            return None
            
        return end_time - start_time
        
    def measure_memory(self, binary, pdf_path, flags=[]):
        """Measure peak memory usage"""
        cmd = ["/usr/bin/time", "-l", binary, "-i", pdf_path, "-o", "/tmp/bench-output.md", "-a", "/tmp/bench-assets", "-d", "144"] + flags
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        # Parse memory usage from stderr
        for line in result.stderr.split('\n'):
            if "maximum resident set size" in line:
                memory_bytes = int(line.split()[0])
                return memory_bytes / (1024 * 1024)
        
        return 0
        
    def run_benchmarks(self, iterations=5):
        """Run complete benchmark suite"""
        results = {
            "objc": {},
            "swift_async": {},
            "swift_gcd": {},
            "swift_ultra": {},
            "comparison": {}
        }
        
        implementations = [
            ("objc", self.objc_binary, []),
            ("swift_async", self.swift_binary, []),
            ("swift_gcd", self.swift_binary, ["--optimized"]),
            ("swift_ultra", self.swift_binary, ["--ultra-optimized"])
        ]
        
        for name, pdf_path, page_count in self.test_pdfs:
            print(f"\n=== Benchmarking {name} PDF ({page_count} pages) ===")
            
            impl_times = {impl_name: [] for impl_name, _, _ in implementations}
            
            # Warm-up run
            print("Warming up...")
            for impl_name, binary, flags in implementations:
                self.run_single_benchmark(binary, pdf_path, "/tmp/warmup.md", "/tmp/warmup-assets", flags)
            
            # Benchmark runs
            print(f"Running {iterations} iterations...")
            for i in range(iterations):
                print(f"  Iteration {i+1}/{iterations}", end="\r")
                
                for impl_name, binary, flags in implementations:
                    time_taken = self.run_single_benchmark(
                        binary, pdf_path, 
                        f"/tmp/{impl_name}-{name}.md", 
                        f"/tmp/{impl_name}-{name}-assets",
                        flags
                    )
                    if time_taken:
                        impl_times[impl_name].append(time_taken)
            
            print()
            
            # Calculate statistics
            for impl_name, times in impl_times.items():
                if times:
                    mean_time = statistics.mean(times)
                    results[impl_name][name] = {
                        "mean_time": mean_time,
                        "min_time": min(times),
                        "max_time": max(times),
                        "stddev": statistics.stdev(times) if len(times) > 1 else 0,
                        "pages_per_second": page_count / mean_time
                    }
            
            # Measure memory
            print("Measuring memory usage...")
            for impl_name, binary, flags in implementations:
                memory = self.measure_memory(binary, pdf_path, flags)
                if impl_name in results and name in results[impl_name]:
                    results[impl_name][name]["peak_memory_mb"] = memory
            
            # Calculate comparisons
            if all(name in results[impl] for impl in ["objc", "swift_async", "swift_gcd", "swift_ultra"]):
                objc_time = results["objc"][name]["mean_time"]
                
                results["comparison"][name] = {
                    "swift_async_vs_objc": results["swift_async"][name]["mean_time"] / objc_time,
                    "swift_gcd_vs_objc": results["swift_gcd"][name]["mean_time"] / objc_time,
                    "swift_ultra_vs_objc": results["swift_ultra"][name]["mean_time"] / objc_time,
                    "gcd_vs_async": results["swift_gcd"][name]["mean_time"] / results["swift_async"][name]["mean_time"],
                    "ultra_vs_async": results["swift_ultra"][name]["mean_time"] / results["swift_async"][name]["mean_time"],
                    "ultra_vs_gcd": results["swift_ultra"][name]["mean_time"] / results["swift_gcd"][name]["mean_time"],
                }
        
        return results
        
    def print_results(self, results):
        """Print formatted benchmark results"""
        print("\n" + "="*80)
        print("COMPREHENSIVE BENCHMARK RESULTS")
        print("="*80)
        
        for pdf_type in ["small", "medium", "large"]:
            if pdf_type in results["objc"]:
                print(f"\n{pdf_type.upper()} PDF:")
                print("-" * 70)
                
                # Print results for each implementation
                for impl_name, display_name in [
                    ("objc", "Objective-C"),
                    ("swift_async", "Swift (async/await)"),
                    ("swift_gcd", "Swift (GCD optimized)"),
                    ("swift_ultra", "Swift (Ultra-optimized)")
                ]:
                    if impl_name in results and pdf_type in results[impl_name]:
                        data = results[impl_name][pdf_type]
                        print(f"\n{display_name}:")
                        print(f"  Mean time: {data['mean_time']:.3f}s")
                        print(f"  Pages/sec: {data['pages_per_second']:.1f}")
                        print(f"  Memory:    {data['peak_memory_mb']:.1f} MB")
                
                # Print comparisons
                if pdf_type in results["comparison"]:
                    comp = results["comparison"][pdf_type]
                    print(f"\nSpeed comparisons (vs ObjC):")
                    print(f"  Swift async:     {comp['swift_async_vs_objc']:.2f}x slower")
                    print(f"  Swift GCD:       {comp['swift_gcd_vs_objc']:.2f}x slower")
                    print(f"  Swift Ultra:     {comp['swift_ultra_vs_objc']:.2f}x slower")
                    
                    print(f"\nOptimization improvements:")
                    gcd_improvement = (1 - comp['gcd_vs_async']) * 100
                    ultra_improvement = (1 - comp['ultra_vs_async']) * 100
                    ultra_vs_gcd = (1 - comp['ultra_vs_gcd']) * 100
                    
                    print(f"  GCD vs async:    {gcd_improvement:+.1f}%")
                    print(f"  Ultra vs async:  {ultra_improvement:+.1f}%")
                    print(f"  Ultra vs GCD:    {ultra_vs_gcd:+.1f}%")
        
        # Save results to JSON
        with open("benchmark-results-all.json", "w") as f:
            json.dump(results, f, indent=2)
        print(f"\nDetailed results saved to benchmark-results-all.json")

def main():
    benchmark = ComprehensiveBenchmark()
    
    # Build implementations
    benchmark.build_implementations()
    
    # Run benchmarks
    results = benchmark.run_benchmarks(iterations=5)
    
    # Print results
    benchmark.print_results(results)

if __name__ == "__main__":
    main()