# Managed by lr-opencode-fork-updater
require "shellwords"

class LrOpencode < Formula
  desc "Precompiled OpenCode fork CLI"
  homepage "https://github.com/leuchtraketen/opencode"
  version "0.0.402441702"
  license "MIT"
  on_macos do
    on_arm do
      url "https://github.com/leuchtraketen/opencode/releases/download/v0.0.0-fork.2fb5ada7772a/lr-opencode-darwin-arm64.zip"
      sha256 "43b3ba9ed510aeead9a5f110308369a146c6979fc851b954daf3b10f4c7edad0"
    end
    on_intel do
      url "https://github.com/leuchtraketen/opencode/releases/download/v0.0.0-fork.2fb5ada7772a/lr-opencode-darwin-x64-baseline.zip"
      sha256 "c15052b4ea59c49a0f956838c41ca1a3b46b9e6baf72f61fab808378e6a65f0b"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/leuchtraketen/opencode/releases/download/v0.0.0-fork.2fb5ada7772a/lr-opencode-linux-arm64.tar.gz"
      sha256 "4f4b637a782560b71c60e8271999523f3fea04083da25c901b257801c56e3770"
    end
    on_intel do
      url "https://github.com/leuchtraketen/opencode/releases/download/v0.0.0-fork.2fb5ada7772a/lr-opencode-linux-x64-baseline.tar.gz"
      sha256 "2df3e03f84a13a23bd603f0ab5bfa50e082c586f75f7977bdff5b898ab4d6074"
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
      Unsigned, not notarized. Binary version: 0.0.0-fork.2fb5ada7772a.
      Homebrew version 0.0.402441702 tracks the monotonically increasing release ID.
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
    assert_equal "0.0.0-fork.2fb5ada7772a", shell_output("#{Shellwords.shellescape((bin/"lr-opencode").to_s)} --version").strip
    assert_match "brew upgrade leuchtraketen/tap/lr-opencode", shell_output("#{Shellwords.shellescape((bin/"lr-opencode").to_s)} --log-level INFO upgrade 2>&1", 1)
  end
end
