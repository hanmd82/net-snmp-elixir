# Copyright © 2015 Jonathan Storm <the.jonathan.storm@gmail.com>
# This work is free. You can redistribute it and/or modify it under the
# terms of the Do What The Fuck You Want To Public License, Version 2,
# as published by Sam Hocevar. See the COPYING.WTFPL file for more details.

defmodule NetSNMP do
  @moduledoc """
  A Net-SNMP library supporting SNMPv1/2c/3.
  """
  alias NetSNMP.Parse

  @doc """
  Returns a keyword list containing the given SNMPv1/2c/3 credentials.

  ## Examples

      iex> NetSNMP.credential [:v1, "public"]
      [version: "1", community: "public"]

      iex> NetSNMP.credential [:v2c, "public"]
      [version: "2c", community: "public"]

      iex> NetSNMP.credential [:v3, :no_auth_no_priv, "user"]
      [version: "3", sec_level: "noAuthNoPriv", sec_name: "user"]

      iex> NetSNMP.credential [:v3, :auth_no_priv, "user", :sha, "authpass"]
      [ version: "3",
        sec_level: "authNoPriv",
        sec_name: "user",
        auth_proto: "sha", auth_pass: "authpass"
      ]

      iex> NetSNMP.credential [:v3, :auth_priv, "user", :sha, "authpass", :aes, "privpass"]
      [ version: "3",
        sec_level: "authPriv",
        sec_name: "user",
        auth_proto: "sha", auth_pass: "authpass",
        priv_proto: "aes", priv_pass: "privpass"
      ]
  """
  @spec credential(list) :: Keyword.t
  def credential(args) do
    case args do
      [:v1, _] ->
        apply &credential/2, args

      [:v2c, _] ->
        apply &credential/2, args

      [:v3, :no_auth_no_priv, _] ->
        apply &credential/3, args

      [:v3, :auth_no_priv, _, _, _] ->
        apply &credential/5, args

      [:v3, :auth_priv, _, _, _, _, _] ->
        apply &credential/7, args
    end
  end

  @doc """
  Returns a keyword list containing the given SNMPv1/2c community.

  ## Examples

      iex> NetSNMP.credential :v1, "public"
      [version: "1", community: "public"]

      iex> NetSNMP.credential :v2c, "public"
      [version: "2c", community: "public"]
  """
  @spec credential(:v1, String.t) :: Keyword.t
  @spec credential(:v2c, String.t) :: Keyword.t

  def credential(version, community)
  def credential(:v1, community) do
    [ version: "1",
      community: community
    ]
  end
  def credential(:v2c, community) do
    [ version: "2c",
      community: community
    ]
  end

  @doc """
  Returns a keyword list containing the given SNMPv3 noAuthNoPriv credentials.

  ## Examples

      iex> NetSNMP.credential :v3, :no_auth_no_priv, "user"
      [version: "3", sec_level: "noAuthNoPriv", sec_name: "user"]
  """
  @spec credential(:v3, :no_auth_no_priv, String.t) :: Keyword.t

  def credential(version, sec_level, sec_name)
  def credential(:v3, :no_auth_no_priv, sec_name) do
    [ version: "3",
      sec_level: "noAuthNoPriv",
      sec_name: sec_name
    ]
  end

  @doc """
  Returns a keyword list containing the given SNMPv3 authNoPriv credentials.

  ## Examples

      iex> NetSNMP.credential :v3, :auth_no_priv, "user", :sha, "authpass"
      [ version: "3",
        sec_level: "authNoPriv",
        sec_name: "user",
        auth_proto: "sha", auth_pass: "authpass"
      ]
  """
  @spec credential(:v3, :auth_no_priv, String.t, :md5|:sha, String.t) :: Keyword.t

  def credential(version, sec_level, sec_name, auth_proto, auth_pass)
  def credential(:v3, :auth_no_priv, sec_name, auth_proto, auth_pass)
      when auth_proto in [:md5, :sha]
  do
    [ version: "3",
      sec_level: "authNoPriv",
      sec_name: sec_name,
      auth_proto: to_string(auth_proto),
      auth_pass: auth_pass
    ]
  end

  @doc """
  Returns a keyword list containing the given SNMPv3 authPriv credentials.

  ## Examples

      iex> NetSNMP.credential :v3, :auth_priv, "user", :sha, "authpass", :aes, "privpass"
      [ version: "3",
        sec_level: "authPriv",
        sec_name: "user",
        auth_proto: "sha", auth_pass: "authpass",
        priv_proto: "aes", priv_pass: "privpass"
      ]
  """
  @spec credential(:v3, :auth_priv, String.t, :md5|:sha, String.t, :des|:aes, String.t) :: Keyword.t

  def credential(version, sec_level, sec_name, auth_proto, auth_pass, priv_proto, priv_pass)
  def credential(:v3, :auth_priv, sec_name, auth_proto, auth_pass, priv_proto, priv_pass)
      when auth_proto in [:md5, :sha]
       and priv_proto in [:des, :aes]
  do
    [ version: "3",
      sec_level: "authPriv",
      sec_name: sec_name,
      auth_proto: to_string(auth_proto),
      auth_pass: auth_pass,
      priv_proto: to_string(priv_proto),
      priv_pass: priv_pass
    ]
  end

  defp _credential_to_snmpcmd_args([], acc) do
    Enum.join acc, " "
  end
  defp _credential_to_snmpcmd_args([{:version, version}|tail], acc) do
    _credential_to_snmpcmd_args tail, ["-v#{version}"|acc]
  end
  defp _credential_to_snmpcmd_args([{:community, community}|tail], acc) do
    _credential_to_snmpcmd_args tail, acc ++ ["-c '#{community}'"]
  end
  defp _credential_to_snmpcmd_args([{:sec_level, sec_level}|tail], acc) do
    _credential_to_snmpcmd_args tail, acc ++ ["-l#{sec_level}"]
  end
  defp _credential_to_snmpcmd_args([{:sec_name, sec_name}|tail], acc) do
    _credential_to_snmpcmd_args tail, acc ++ ["-u '#{sec_name}'"]
  end
  defp _credential_to_snmpcmd_args([{:auth_proto, auth_proto}|tail], acc) do
    _credential_to_snmpcmd_args tail, acc ++ ["-a #{auth_proto}"]
  end
  defp _credential_to_snmpcmd_args([{:auth_pass, auth_pass}|tail], acc) do
    _credential_to_snmpcmd_args tail, acc ++ ["-A '#{auth_pass}'"]
  end
  defp _credential_to_snmpcmd_args([{:priv_proto, priv_proto}|tail], acc) do
    _credential_to_snmpcmd_args tail, acc ++ ["-x #{priv_proto}"]
  end
  defp _credential_to_snmpcmd_args([{:priv_pass, priv_pass}|tail], acc) do
    _credential_to_snmpcmd_args tail, acc ++ ["-X '#{priv_pass}'"]
  end

  defp credential_to_snmpcmd_args(credential) do
    _credential_to_snmpcmd_args credential, []
  end

  defp uri_to_agent_string(uri) do
    "udp:#{uri.host}:#{uri.port || 161}"
  end

  defp objects_to_oids(snmp_objects) do
    Enum.map snmp_objects, fn object ->
      object
        |> SNMPMIB.Object.oid
        |> SNMPMIB.list_oid_to_string
    end
  end

  defp get_field_delimiter do
    Application.get_env :net_snmp_ex, :field_delimiter
  end

  defp get_max_repetitions do
    Application.get_env :net_snmp_ex, :max_repetitions
  end

  defp gen_snmpcmd(:get, snmp_objects, uri, credential, context) do
    [ "snmpget -Le -mALL -OUnet -n '#{context}'",
      credential_to_snmpcmd_args(credential),
      uri_to_agent_string(uri) | objects_to_oids(snmp_objects)

    ] |> Enum.join(" ")
  end
  defp gen_snmpcmd(:set, snmp_objects, uri, credential, context) do
    [ "snmpset -Le -mALL -OUnet -n '#{context}'",
      credential_to_snmpcmd_args(credential),
      uri_to_agent_string(uri) | Enum.map(snmp_objects, &to_string/1)

    ] |> Enum.join(" ")
  end
  defp gen_snmpcmd(:walk, snmp_object, uri, credential, context) do
    [ "snmpwalk -Le -mALL -OUnet -n '#{context}'",
      credential_to_snmpcmd_args(credential),
      uri_to_agent_string(uri) | objects_to_oids([snmp_object])

    ] |> Enum.join(" ")
  end
  defp gen_snmpcmd(:table, snmp_object, uri, credential, context) do
    max_reps = get_max_repetitions()
    delim = get_field_delimiter()

    [ "snmptable -Le -mALL -Cr #{max_reps} -Clibf '#{delim}' -OXUet -n '#{context}'",
      credential_to_snmpcmd_args(credential),
      uri_to_agent_string(uri) | objects_to_oids([snmp_object])

    ] |> Enum.join(" ")
  end

  defp shell_cmd(command) do
    command
      |> :binary.bin_to_list
      |> :os.cmd
      |> :binary.list_to_bin
  end

  # TODO: When URI.parse receives a bare IP, it puts this in :path rather than
  #       :host. Since we rely on :host, we shouldn't accept a %{host: nil}.
  #       Since the API is showing cracks (SNMPMIB), queue this up for later.

  @doc """
  Send SNMPGET request to `uri` for given objects and credentials.
  """
  def get(snmp_object, uri, credential, context \\ "")
  def get(snmp_objects, uri, credential, context) when is_list snmp_objects do
    gen_snmpcmd(:get, snmp_objects, uri, credential, context)
      |> shell_cmd
      |> Parse.parse_snmp_output
  end
  def get(snmp_object, uri, credential, context) do
    get [snmp_object], uri, credential, context
  end

  @doc """
  Send SNMPSET request to `uri` for given objects and credentials.
  """
  def set(snmp_object, uri, credential, context \\ "")
  def set(snmp_objects, uri, credential, context) when is_list snmp_objects do
    gen_snmpcmd(:set, snmp_objects, uri, credential, context)
      |> shell_cmd
      |> Parse.parse_snmp_output
  end
  def set(snmp_object, uri, credential, context) do
    set [snmp_object], uri, credential, context
  end

  @doc """
  Perform SNMP table operations against `uri` for given objects and credentials.
  """
  def table(snmp_object, uri, credential, context \\ "")
  def table(snmp_objects, uri, credential, context) when is_list snmp_objects do
    snmp_objects
      |> Enum.map(&table(&1, uri, credential, context))
      |> List.flatten
  end
  def table(snmp_object, uri, credential, context) do
    gen_snmpcmd(:table, snmp_object, uri, credential, context)
      |> shell_cmd
      |> Parse.parse_snmp_table_output
  end

  @doc """
  Send SNMPGETNEXT requests to `uri`, starting at given objects, with given
  credentials.
  """
  def walk(snmp_object, uri, credential, context \\ "")
  def walk(snmp_objects, uri, credential, context) when is_list snmp_objects do
    snmp_objects
      |> Enum.map(&walk(&1, uri, credential, context))
      |> List.flatten
  end
  def walk(snmp_object, uri, credential, context) do
    gen_snmpcmd(:walk, snmp_object, uri, credential, context)
      |> shell_cmd
      |> Parse.parse_snmp_output
  end
end

