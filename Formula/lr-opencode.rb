# Managed by lr-opencode-fork-updater
require "shellwords"

class LrOpencode < Formula
  desc "Precompiled OpenCode fork CLI"
  homepage "https://github.com/leuchtraketen/opencode"
  version "0.0.386651208"
  license "MIT"
  on_macos do
    on_arm do
      url "https://github.com/leuchtraketen/opencode/releases/download/v0.0.0-fork.917919f3b6a2/lr-opencode-darwin-arm64.zip"
      sha256 "e13dbe3ef78f37fac49f8f7190cf64071ffcab17b5adf1d11f8cba65db0d0836"
    end
    on_intel do
      url "https://github.com/leuchtraketen/opencode/releases/download/v0.0.0-fork.917919f3b6a2/lr-opencode-darwin-x64-baseline.zip"
      sha256 "16be164c75b63da33fbd7e25d67cfbc895a329b83f18c18c33a700b3a0898b00"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/leuchtraketen/opencode/releases/download/v0.0.0-fork.917919f3b6a2/lr-opencode-linux-arm64.tar.gz"
      sha256 "5d07bebed9b4ff603852674098f4e696df91c7f6ee1ca08023e0ab7f5ba8b4c8"
    end
    on_intel do
      url "https://github.com/leuchtraketen/opencode/releases/download/v0.0.0-fork.917919f3b6a2/lr-opencode-linux-x64-baseline.tar.gz"
      sha256 "7b6e8acdea4817bcca229beaab9f48f9f1db3150b37d45ac1dabbc4acfe3865e"
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
      Unsigned, not notarized. Binary version: 0.0.0-fork.917919f3b6a2.
      Homebrew version 0.0.386651208 tracks the monotonically increasing release ID.
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
    assert_equal "0.0.0-fork.917919f3b6a2", shell_output("#{Shellwords.shellescape((bin/"lr-opencode").to_s)} --version").strip
    assert_match "brew upgrade leuchtraketen/tap/lr-opencode", shell_output("#{Shellwords.shellescape((bin/"lr-opencode").to_s)} --log-level INFO upgrade 2>&1", 1)
  end
end
