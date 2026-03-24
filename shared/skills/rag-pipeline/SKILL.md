---
name: brain-rag-pipeline
description: Design and build RAG (Retrieval-Augmented Generation) pipelines with proper chunking, embedding, retrieval, and evaluation strategies. Use when building search, Q&A, or document processing systems.
---

# RAG Pipeline Design

When the user needs to build or improve a RAG system:

## Step 1: Understand the Data

Ask these questions before designing:
1. What document types? (PDF, markdown, code, structured data)
2. How much data? (hundreds vs millions of docs)
3. Query patterns? (keyword search, semantic Q&A, hybrid)
4. Freshness requirements? (real-time vs batch indexing)
5. Accuracy requirements? (precision vs recall trade-off)

## Step 2: Choose the Architecture

```
Documents -> Ingestion -> Chunking -> Embedding -> Vector Store
                                                        |
User Query -> Query Processing -> Retrieval -> Reranking -> LLM -> Response
```

### Ingestion Patterns

| Source | Parser | Notes |
|--------|--------|-------|
| PDF | PyMuPDF / pdfplumber | pdfplumber for tables |
| HTML | BeautifulSoup + markdownify | Strip nav/footer |
| Code | tree-sitter | Chunk by function/class |
| Markdown | Custom splitter | Respect heading hierarchy |

### Chunking Strategy

**Rule of thumb:** Chunk size = 512-1024 tokens for most use cases.

```python
# Recursive character splitter (most common)
chunk_size = 800
chunk_overlap = 200  # 20-25% overlap

# Semantic chunking (better quality, slower)
# Split on: headings > paragraphs > sentences > tokens
```

**Critical rules:**
- Never split mid-sentence
- Preserve metadata (source, page, section heading)
- Add parent context: prepend section title to each chunk
- Strip NUL bytes before storing (PostgreSQL requirement)

### Embedding Models

| Model | Dim | Speed | Quality | Cost |
|-------|-----|-------|---------|------|
| text-embedding-3-small | 1536 | Fast | Good | Cheap |
| text-embedding-3-large | 3072 | Medium | Better | 2x |
| voyage-3 | 1024 | Medium | Best | 3x |
| BGE-M3 (local) | 1024 | Slow | Good | Free |

**Always:** Normalize embeddings, use cosine similarity.

### Vector Store Selection

| Store | Scale | Features | Best for |
|-------|-------|----------|----------|
| pgvector | <1M docs | SQL + vectors | Existing PostgreSQL stack |
| Qdrant | Any | Filtering, payloads | Production RAG |
| Pinecone | Any | Managed, serverless | Quick start |
| ChromaDB | <100K | Simple API | Prototyping |

## Step 3: Retrieval Strategy

### Hybrid Search (recommended default)

```python
# Combine dense (semantic) + sparse (keyword) retrieval
dense_results = vector_search(query_embedding, top_k=20)
sparse_results = bm25_search(query_text, top_k=20)

# Reciprocal Rank Fusion
combined = rrf_merge(dense_results, sparse_results, k=60)
```

### Reranking (improves precision by 15-30%)

```python
# Cross-encoder reranker after initial retrieval
reranked = cross_encoder.rerank(
    query=query,
    documents=combined[:20],  # Rerank top 20
    top_k=5                   # Return top 5
)
```

### Query Processing

```python
# 1. Query expansion (optional, improves recall)
expanded = llm.expand_query(original_query)

# 2. HyDE: generate hypothetical answer, embed that
hypothetical_answer = llm.generate(f"Answer this: {query}")
search_embedding = embed(hypothetical_answer)
```

## Step 4: Context Assembly

```python
# Build context window for LLM
def build_context(chunks: list[Chunk], max_tokens: int = 4000) -> str:
    context_parts = []
    token_count = 0
    for chunk in chunks:
        chunk_tokens = count_tokens(chunk.text)
        if token_count + chunk_tokens > max_tokens:
            break
        context_parts.append(
            f"[Source: {chunk.metadata['source']}, Page {chunk.metadata.get('page', '?')}]\n"
            f"{chunk.text}"
        )
        token_count += chunk_tokens
    return "\n\n---\n\n".join(context_parts)
```

## Step 5: Evaluation

**Always measure before optimizing.**

| Metric | What it measures | Target |
|--------|------------------|--------|
| Retrieval Recall@k | Does the right chunk appear in top k? | >85% |
| Answer Correctness | Is the generated answer correct? | >80% |
| Faithfulness | Does the answer stick to retrieved context? | >90% |
| Latency p95 | End-to-end response time | <3s |

```python
# Minimal eval set: 50-100 question-answer pairs
eval_set = [
    {"question": "...", "expected_answer": "...", "expected_source": "..."},
]
```

## Step 6: Common Pitfalls

- Chunks too large -> irrelevant context, wasted tokens
- Chunks too small -> missing context, fragmented answers
- No overlap -> information lost at chunk boundaries
- No metadata filtering -> wrong documents retrieved
- No reranking -> low precision in top results
- No evaluation -> optimizing blind
- Embedding model mismatch -> query and doc embeddings incompatible
