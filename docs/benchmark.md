# IParty

## Benchmark

This is the result of `script/benchmark.rb` on my M1.

```
RSS-before[uncached]: 30.31 MB
ruby 3.3.6 (2024-11-05 revision 75015d4c1f) [arm64-darwin21]
Warming up --------------------------------------
            uncached   145.000 i/100ms
Calculating -------------------------------------
            uncached      1.448k (± 1.9%) i/s  (690.59 μs/i) -     14.500k in  10.017464s
RSS-after[uncached]: 48.75 MB


RSS-before[singletons]: 29.77 MB
ruby 3.3.6 (2024-11-05 revision 75015d4c1f) [arm64-darwin21]
Warming up --------------------------------------
          singletons   162.000 i/100ms
Calculating -------------------------------------
          singletons      1.565k (± 8.0%) i/s  (638.87 μs/i) -     15.552k in  10.006033s
RSS-after[singletons]: 31.27 MB


RSS-before[eager_load]: 30.20 MB
ruby 3.3.6 (2024-11-05 revision 75015d4c1f) [arm64-darwin21]
Warming up --------------------------------------
          eager_load   500.000 i/100ms
Calculating -------------------------------------
          eager_load      4.940k (± 4.1%) i/s  (202.43 μs/i) -     49.500k in  10.038651s
RSS-after[eager_load]: 112.73 MB
```

### Personal conclusion

I personally would rather not have mmdb-freshness tied to app-boot.
Hence I personally use no singletons unless I heavily use IParty in which case I would use the
CurrentAttributes way of caching non-eagerly-loaded instances per request with an additional per-request ipcache.
See documentation for more details.
