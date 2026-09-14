# Managed by lr-opencode-fork-updater
require "shellwords"

class LrOpencode < Formula
  desc "Precompiled OpenCode fork CLI"
  homepage "https://github.com/leuchtraketen/opencode"
  version "0.0.388281989"
  license "MIT"
  on_macos do
    on_arm do
      url "https://github.com/leuchtraketen/opencode/releases/download/v0.0.0-fork.727a6e3ba2d4/lr-opencode-darwin-arm64.zip"
      sha256 "aeb122cb90b4178fb33cd02cdec59c4197c5b119a79984d5b5421690f59a837e"
    end
    on_intel do
      url "https://github.com/leuchtraketen/opencode/releases/download/v0.0.0-fork.727a6e3ba2d4/lr-opencode-darwin-x64-baseline.zip"
      sha256 "6ff294d0510870a04b2674b9c82b3cc556a8c178e1f92dafadac858eaf5dd69b"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/leuchtraketen/opencode/releases/download/v0.0.0-fork.727a6e3ba2d4/lr-opencode-linux-arm64.tar.gz"
      sha256 "4248cc6be86ef98bea546dac37d0b91248cdf6322b3536a2b9cdd5871540b496"
    end
    on_intel do
      url "https://github.com/leuchtraketen/opencode/releases/download/v0.0.0-fork.727a6e3ba2d4/lr-opencode-linux-x64-baseline.tar.gz"
      sha256 "36920520e23e4d89a374decbefcc30dc1f1d99983545d23ac8300e3f35b70303"
    end
  end

  def install
    libexec.install "lr-opencode"
    bin.mkpath
    (bin/"lr-opencode").write <<~SH
      #!/bin/sh
      export OPENCODE_DISABLE_AUTOUPDATE=1
      lr_skip_value=0
      lr_boolean_value=0
      for lr_argument do
        if [ "$lr_skip_value" = 1 ]; then
          lr_skip_value=0
          continue
        fi
        if [ "$lr_boolean_value" = 1 ]; then
          lr_boolean_value=0
          case "$lr_argument" in true|false) continue ;; esac
        fi
        case "$lr_argument" in
          --) break ;;
          --log-level|--logLevel|--port|--hostname|--mdns-domain|--mdnsDomain|--cors|--method|-m)
            lr_skip_value=1 ;;
          --print-logs|--printLogs|--pure|--mdns|--help|-h|--version|-v)
            lr_boolean_value=1 ;;
          --*=*|-*) ;;
          upgrade)
            printf '%s\\n' 'Use brew upgrade leuchtraketen/tap/lr-opencode' >&2
            exit 1 ;;
          *) break ;;
        esac
      done
      exec #{Shellwords.shellescape((libexec/"lr-opencode").to_s)} "$@"
    SH
    chmod 0755, bin/"lr-opencode"
  end

  def caveats
    <<~EOS
      Unsigned, not notarized. Binary version: 0.0.0-fork.727a6e3ba2d4.
      Homebrew version 0.0.388281989 tracks the monotonically increasing release ID.
      Uses the existing OpenCode config, auth, data and state paths.
      Update with: brew upgrade leuchtraketen/tap/lr-opencode
    EOS
  end

  test do
    ENV["HOME"] = testpath.to_s
    ENV["XDG_CONFIG_HOME"] = (testpath/"config").to_s
    ENV["XDG_DATA_HOME"] = (testpath/"data").to_s
    ENV["XDG_STATE_HOME"] = (testpath/"state").to_s
    ENV["XDG_CACHE_HOME"] = (testpath/"cache").to_s
    ENV["OPENCODE_DISABLE_MODELS_FETCH"] = "1"
    assert_equal "0.0.0-fork.727a6e3ba2d4", shell_output("#{Shellwords.shellescape((bin/"lr-opencode").to_s)} --version").strip
    assert_match "brew upgrade leuchtraketen/tap/lr-opencode", shell_output("#{Shellwords.shellescape((bin/"lr-opencode").to_s)} --log-level INFO upgrade 2>&1", 1)
  end
end
