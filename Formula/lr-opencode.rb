# Managed by lr-opencode-fork-updater
require "shellwords"

class LrOpencode < Formula
  desc "Precompiled OpenCode fork CLI"
  homepage "https://github.com/leuchtraketen/opencode"
  version "0.0.385623085"
  license "MIT"
  on_macos do
    on_arm do
      url "https://github.com/leuchtraketen/opencode/releases/download/v0.0.0-fork.c32b520edfbf/lr-opencode-darwin-arm64.zip"
      sha256 "92fe268fb4335a895a3144b4abef03619669e75cda8fc9c51b16c656c5c3dc60"
    end
    on_intel do
      url "https://github.com/leuchtraketen/opencode/releases/download/v0.0.0-fork.c32b520edfbf/lr-opencode-darwin-x64-baseline.zip"
      sha256 "4570008af54aa8ce68b111ffd34a962c912ab8c07ac6dba00dad6fe6ecf755bd"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/leuchtraketen/opencode/releases/download/v0.0.0-fork.c32b520edfbf/lr-opencode-linux-arm64.tar.gz"
      sha256 "63636ef840bcf4ebcf804a74ff1b2b37f29ab864af52abcff2367f13a750bc2f"
    end
    on_intel do
      url "https://github.com/leuchtraketen/opencode/releases/download/v0.0.0-fork.c32b520edfbf/lr-opencode-linux-x64-baseline.tar.gz"
      sha256 "4d61228116490220fc9c658ee756ff6273364290e6b9ec8f8e5f4d930a295adb"
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
      Unsigned, not notarized. Binary version: 0.0.0-fork.c32b520edfbf.
      Homebrew version 0.0.385623085 tracks the monotonically increasing release ID.
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
    assert_equal "0.0.0-fork.c32b520edfbf", shell_output("#{Shellwords.shellescape((bin/"lr-opencode").to_s)} --version").strip
    assert_match "brew upgrade leuchtraketen/tap/lr-opencode", shell_output("#{Shellwords.shellescape((bin/"lr-opencode").to_s)} --log-level INFO upgrade 2>&1", 1)
  end
end
