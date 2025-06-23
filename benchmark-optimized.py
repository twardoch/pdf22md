#!/usr/bin/env python3
"""
Performance benchmark comparing all three implementations:
- Objective-C
- Swift (async/await)
- Swift Optimized (GCD)
"""

import subprocess
import time
import os
import statistics
import json
from pathlib import Path

class PDFBenchmarkOptimized:
    def __init__(self):
        self.objc_binary = "./pdf22md"
        self.swift_binary = "./swift/.build/release/pdf22md-swift"
        self.test_pdfs = [
            ("small", "test/small.pdf", 5),
            ("medium", "test/medium.pdf", 50),
            ("large", "test/large.pdf", 200),
        ]
        
    def build_implementations(self):
        """Build both implementations in release mode"""
        print("Building Objective-C implementation...")
        subprocess.run(["make", "clean"], check=True)
        subprocess.run(["make"], check=True)
        
        print("Building Swift implementation (release mode)...")
        subprocess.run(["swift", "build", "-c", "release"], cwd="swift", check=True)
        print()
        
    def run_single_benchmark(self, binary, pdf_path, output_path, assets_path, use_optimized=False):
        """Run a single benchmark and return timing"""
        # Clean up previous outputs
        for path in [output_path, assets_path]:
            if os.path.exists(path):
                if os.path.isdir(path):
                    subprocess.run(["rm", "-rf", path])
                else:
                    os.remove(path)
        
        # Build command
        cmd = [
            binary,
            "-i", pdf_path,
            "-o", output_path,
            "-a", assets_path,
            "-d", "144"
        ]
        
        if use_optimized and binary.endswith("pdf22md-swift"):
            cmd.append("--optimized")
        
        # Measure execution time
        start_time = time.perf_counter()
        
        process = subprocess.run(cmd, capture_output=True, text=True)
        
        end_time = time.perf_counter()
        
        if process.returncode != 0:
            print(f"Error running {binary}: {process.stderr}")
            return None
            
        return end_time - start_time
        
    def measure_memory(self, binary, pdf_path, use_optimized=False):
        """Measure peak memory usage"""
        cmd = [
            "/usr/bin/time", "-l",
            binary,
            "-i", pdf_path,
            "-o", "/tmp/bench-output.md",
            "-a", "/tmp/bench-assets",
            "-d", "144"
        ]
        
        if use_optimized and binary.endswith("pdf22md-swift"):
            cmd.append("--optimized")
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        # Parse memory usage from stderr
        for line in result.stderr.split('\n'):
            if "maximum resident set size" in line:
                # Extract memory in bytes and convert to MB
                memory_bytes = int(line.split()[0])
                return memory_bytes / (1024 * 1024)
        
        return 0
        
    def run_benchmarks(self, iterations=5):
        """Run complete benchmark suite"""
        results = {
            "objc": {},
            "swift_async": {},
            "swift_optimized": {},
            "comparison": {}
        }
        
        for name, pdf_path, page_count in self.test_pdfs:
            print(f"\n=== Benchmarking {name} PDF ({page_count} pages) ===")
            
            objc_times = []
            swift_async_times = []
            swift_opt_times = []
            
            # Warm-up run
            print("Warming up...")
            self.run_single_benchmark(self.objc_binary, pdf_path, "/tmp/warmup.md", "/tmp/warmup-assets")
            self.run_single_benchmark(self.swift_binary, pdf_path, "/tmp/warmup.md", "/tmp/warmup-assets")
            self.run_single_benchmark(self.swift_binary, pdf_path, "/tmp/warmup.md", "/tmp/warmup-assets", use_optimized=True)
            
            # Benchmark runs
            print(f"Running {iterations} iterations...")
            for i in range(iterations):
                print(f"  Iteration {i+1}/{iterations}", end="\r")
                
                # ObjC benchmark
                objc_time = self.run_single_benchmark(
                    self.objc_binary, pdf_path, 
                    f"/tmp/objc-{name}.md", f"/tmp/objc-{name}-assets"
                )
                if objc_time:
                    objc_times.append(objc_time)
                
                # Swift async/await benchmark  
                swift_async_time = self.run_single_benchmark(
                    self.swift_binary, pdf_path,
                    f"/tmp/swift-async-{name}.md", f"/tmp/swift-async-{name}-assets"
                )
                if swift_async_time:
                    swift_async_times.append(swift_async_time)
                    
                # Swift optimized benchmark
                swift_opt_time = self.run_single_benchmark(
                    self.swift_binary, pdf_path,
                    f"/tmp/swift-opt-{name}.md", f"/tmp/swift-opt-{name}-assets",
                    use_optimized=True
                )
                if swift_opt_time:
                    swift_opt_times.append(swift_opt_time)
            
            print()
            
            # Calculate statistics
            if objc_times:
                objc_mean = statistics.mean(objc_times)
                results["objc"][name] = {
                    "mean_time": objc_mean,
                    "min_time": min(objc_times),
                    "max_time": max(objc_times),
                    "stddev": statistics.stdev(objc_times) if len(objc_times) > 1 else 0,
                    "pages_per_second": page_count / objc_mean
                }
                
            if swift_async_times:
                swift_async_mean = statistics.mean(swift_async_times)
                results["swift_async"][name] = {
                    "mean_time": swift_async_mean,
                    "min_time": min(swift_async_times),
                    "max_time": max(swift_async_times),
                    "stddev": statistics.stdev(swift_async_times) if len(swift_async_times) > 1 else 0,
                    "pages_per_second": page_count / swift_async_mean
                }
                
            if swift_opt_times:
                swift_opt_mean = statistics.mean(swift_opt_times)
                results["swift_optimized"][name] = {
                    "mean_time": swift_opt_mean,
                    "min_time": min(swift_opt_times),
                    "max_time": max(swift_opt_times),
                    "stddev": statistics.stdev(swift_opt_times) if len(swift_opt_times) > 1 else 0,
                    "pages_per_second": page_count / swift_opt_mean
                }
                
            # Comparisons
            if objc_times and swift_async_times and swift_opt_times:
                results["comparison"][name] = {
                    "swift_async_vs_objc": swift_async_mean / objc_mean,
                    "swift_opt_vs_objc": swift_opt_mean / objc_mean,
                    "swift_opt_vs_async": swift_opt_mean / swift_async_mean,
                    "objc_faster_than_async": ((swift_async_mean / objc_mean) - 1) * 100,
                    "objc_faster_than_opt": ((swift_opt_mean / objc_mean) - 1) * 100,
                    "opt_faster_than_async": ((swift_async_mean / swift_opt_mean) - 1) * 100
                }
                
                # Measure memory
                print("Measuring memory usage...")
                objc_memory = self.measure_memory(self.objc_binary, pdf_path)
                swift_async_memory = self.measure_memory(self.swift_binary, pdf_path)
                swift_opt_memory = self.measure_memory(self.swift_binary, pdf_path, use_optimized=True)
                
                results["objc"][name]["peak_memory_mb"] = objc_memory
                results["swift_async"][name]["peak_memory_mb"] = swift_async_memory
                results["swift_optimized"][name]["peak_memory_mb"] = swift_opt_memory
        
        return results
        
    def print_results(self, results):
        """Print formatted benchmark results"""
        print("\n" + "="*70)
        print("BENCHMARK RESULTS - THREE-WAY COMPARISON")
        print("="*70)
        
        for pdf_type in ["small", "medium", "large"]:
            if pdf_type in results["objc"]:
                print(f"\n{pdf_type.upper()} PDF:")
                print("-" * 60)
                
                objc = results["objc"][pdf_type]
                swift_async = results["swift_async"][pdf_type]
                swift_opt = results["swift_optimized"][pdf_type]
                comp = results["comparison"][pdf_type]
                
                print(f"Objective-C:")
                print(f"  Mean time: {objc['mean_time']:.3f}s")
                print(f"  Pages/sec: {objc['pages_per_second']:.1f}")
                print(f"  Memory:    {objc['peak_memory_mb']:.1f} MB")
                
                print(f"\nSwift (async/await):")
                print(f"  Mean time: {swift_async['mean_time']:.3f}s")
                print(f"  Pages/sec: {swift_async['pages_per_second']:.1f}")
                print(f"  Memory:    {swift_async['peak_memory_mb']:.1f} MB")
                
                print(f"\nSwift (GCD optimized):")
                print(f"  Mean time: {swift_opt['mean_time']:.3f}s")
                print(f"  Pages/sec: {swift_opt['pages_per_second']:.1f}")
                print(f"  Memory:    {swift_opt['peak_memory_mb']:.1f} MB")
                
                print(f"\nComparison:")
                print(f"  ObjC is {comp['objc_faster_than_async']:.1f}% faster than Swift async")
                print(f"  ObjC is {comp['objc_faster_than_opt']:.1f}% faster than Swift optimized")
                print(f"  Swift optimized is {comp['opt_faster_than_async']:.1f}% faster than Swift async")
        
        # Save results to JSON
        with open("benchmark-results-optimized.json", "w") as f:
            json.dump(results, f, indent=2)
        print(f"\nDetailed results saved to benchmark-results-optimized.json")

def main():
    benchmark = PDFBenchmarkOptimized()
    
    # Build implementations
    benchmark.build_implementations()
    
    # Run benchmarks
    results = benchmark.run_benchmarks(iterations=5)
    
    # Print results
    benchmark.print_results(results)

if __name__ == "__main__":
    main()