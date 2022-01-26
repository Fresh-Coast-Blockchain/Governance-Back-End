import { PageHeader } from "antd";
import React from "react";

// displays a page header

export default function Header() {
  return (
    <PageHeader
      title="⚖️ Governor Creator"
      subTitle="Create your own governance instance with no code!"
      style={{ cursor: "pointer" }}
    />
  );
}
