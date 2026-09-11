# Managed by lr-opencode-fork-updater
require "shellwords"

class LrOpencode < Formula
  desc "Precompiled OpenCode fork CLI"
  homepage "https://github.com/leuchtraketen/opencode"
  version "0.0.386699633"
  license "MIT"
  on_macos do
    on_arm do
      url "https://github.com/leuchtraketen/opencode/releases/download/v0.0.0-fork.f0f30268b89f/lr-opencode-darwin-arm64.zip"
      sha256 "fcdba5dd74d7c5d25779bcda78410db3612a4403aac26be7a2d45877acbe4030"
    end
    on_intel do
      url "https://github.com/leuchtraketen/opencode/releases/download/v0.0.0-fork.f0f30268b89f/lr-opencode-darwin-x64-baseline.zip"
      sha256 "a154c08e0a7af7be2a9ec1a45c2b88144829e872250acc3ca58e0ad107140fe8"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/leuchtraketen/opencode/releases/download/v0.0.0-fork.f0f30268b89f/lr-opencode-linux-arm64.tar.gz"
      sha256 "e143fd95342aa9fa73a85259e0e1ef8d2d032f9e301dfa1b34fcae22c6b29d29"
    end
    on_intel do
      url "https://github.com/leuchtraketen/opencode/releases/download/v0.0.0-fork.f0f30268b89f/lr-opencode-linux-x64-baseline.tar.gz"
      sha256 "9b248838794007aa6a932cb76b4bbb6b638c476f218e6dcfe0cbfe8149dd01f3"
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
      Unsigned, not notarized. Binary version: 0.0.0-fork.f0f30268b89f.
      Homebrew version 0.0.386699633 tracks the monotonically increasing release ID.
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
    assert_equal "0.0.0-fork.f0f30268b89f", shell_output("#{Shellwords.shellescape((bin/"lr-opencode").to_s)} --version").strip
    assert_match "brew upgrade leuchtraketen/tap/lr-opencode", shell_output("#{Shellwords.shellescape((bin/"lr-opencode").to_s)} --log-level INFO upgrade 2>&1", 1)
  end
end
