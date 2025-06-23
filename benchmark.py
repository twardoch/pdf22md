#!/usr/bin/env python3
"""
PDF22MD Performance Benchmark
Compares Objective-C and Swift implementations
"""

import subprocess
import time
import os
import statistics
import json
from pathlib import Path

class PDFBenchmark:
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
        
    def run_single_benchmark(self, binary, pdf_path, output_path, assets_path):
        """Run a single benchmark and return timing"""
        # Clean up previous outputs
        for path in [output_path, assets_path]:
            if os.path.exists(path):
                if os.path.isdir(path):
                    subprocess.run(["rm", "-rf", path])
                else:
                    os.remove(path)
        
        # Measure execution time
        start_time = time.perf_counter()
        
        process = subprocess.run([
            binary,
            "-i", pdf_path,
            "-o", output_path,
            "-a", assets_path,
            "-d", "144"
        ], capture_output=True, text=True)
        
        end_time = time.perf_counter()
        
        if process.returncode != 0:
            print(f"Error running {binary}: {process.stderr}")
            return None
            
        return end_time - start_time
        
    def measure_memory(self, binary, pdf_path):
        """Measure peak memory usage"""
        # Use /usr/bin/time -l on macOS to get memory stats
        result = subprocess.run([
            "/usr/bin/time", "-l",
            binary,
            "-i", pdf_path,
            "-o", "/tmp/bench-output.md",
            "-a", "/tmp/bench-assets",
            "-d", "144"
        ], capture_output=True, text=True)
        
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
            "swift": {},
            "comparison": {}
        }
        
        for name, pdf_path, page_count in self.test_pdfs:
            print(f"\n=== Benchmarking {name} PDF ({page_count} pages) ===")
            
            objc_times = []
            swift_times = []
            
            # Warm-up run
            print("Warming up...")
            self.run_single_benchmark(self.objc_binary, pdf_path, "/tmp/warmup.md", "/tmp/warmup-assets")
            self.run_single_benchmark(self.swift_binary, pdf_path, "/tmp/warmup.md", "/tmp/warmup-assets")
            
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
                
                # Swift benchmark  
                swift_time = self.run_single_benchmark(
                    self.swift_binary, pdf_path,
                    f"/tmp/swift-{name}.md", f"/tmp/swift-{name}-assets"
                )
                if swift_time:
                    swift_times.append(swift_time)
            
            print()
            
            # Calculate statistics
            if objc_times and swift_times:
                objc_mean = statistics.mean(objc_times)
                swift_mean = statistics.mean(swift_times)
                
                results["objc"][name] = {
                    "mean_time": objc_mean,
                    "min_time": min(objc_times),
                    "max_time": max(objc_times),
                    "stddev": statistics.stdev(objc_times) if len(objc_times) > 1 else 0,
                    "pages_per_second": page_count / objc_mean
                }
                
                results["swift"][name] = {
                    "mean_time": swift_mean,
                    "min_time": min(swift_times),
                    "max_time": max(swift_times),
                    "stddev": statistics.stdev(swift_times) if len(swift_times) > 1 else 0,
                    "pages_per_second": page_count / swift_mean
                }
                
                results["comparison"][name] = {
                    "swift_vs_objc_ratio": swift_mean / objc_mean,
                    "objc_faster_by": ((swift_mean / objc_mean) - 1) * 100
                }
                
                # Measure memory
                print("Measuring memory usage...")
                objc_memory = self.measure_memory(self.objc_binary, pdf_path)
                swift_memory = self.measure_memory(self.swift_binary, pdf_path)
                
                results["objc"][name]["peak_memory_mb"] = objc_memory
                results["swift"][name]["peak_memory_mb"] = swift_memory
                results["comparison"][name]["memory_ratio"] = swift_memory / objc_memory if objc_memory > 0 else 0
        
        return results
        
    def print_results(self, results):
        """Print formatted benchmark results"""
        print("\n" + "="*60)
        print("BENCHMARK RESULTS")
        print("="*60)
        
        for pdf_type in ["small", "medium", "large"]:
            if pdf_type in results["objc"]:
                print(f"\n{pdf_type.upper()} PDF:")
                print("-" * 40)
                
                objc = results["objc"][pdf_type]
                swift = results["swift"][pdf_type]
                comp = results["comparison"][pdf_type]
                
                print(f"Objective-C:")
                print(f"  Mean time: {objc['mean_time']:.3f}s")
                print(f"  Pages/sec: {objc['pages_per_second']:.1f}")
                print(f"  Memory:    {objc['peak_memory_mb']:.1f} MB")
                
                print(f"\nSwift:")
                print(f"  Mean time: {swift['mean_time']:.3f}s")
                print(f"  Pages/sec: {swift['pages_per_second']:.1f}")
                print(f"  Memory:    {swift['peak_memory_mb']:.1f} MB")
                
                print(f"\nComparison:")
                if comp['objc_faster_by'] > 0:
                    print(f"  ObjC is {comp['objc_faster_by']:.1f}% faster")
                else:
                    print(f"  Swift is {-comp['objc_faster_by']:.1f}% faster")
                
                if comp['memory_ratio'] > 1:
                    print(f"  Swift uses {(comp['memory_ratio']-1)*100:.1f}% more memory")
                else:
                    print(f"  Swift uses {(1-comp['memory_ratio'])*100:.1f}% less memory")
        
        # Save results to JSON
        with open("benchmark-results.json", "w") as f:
            json.dump(results, f, indent=2)
        print(f"\nDetailed results saved to benchmark-results.json")

def main():
    benchmark = PDFBenchmark()
    
    # Build implementations
    benchmark.build_implementations()
    
    # Run benchmarks
    results = benchmark.run_benchmarks(iterations=5)
    
    # Print results
    benchmark.print_results(results)

if __name__ == "__main__":
    main()