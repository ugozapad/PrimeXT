/*
gl_gpubuffer.h - OpenGL Buffer object wrapper
Copyright (C) 2026

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
*/

#ifndef GPU_BUFFER_H
#define GPU_BUFFER_H

enum BufferType
{
	BT_VERTEX,
	BT_INDEX,

	BT_MAX
};

enum BufferAccess
{
	BA_READ_ONLY,
	BA_WRITE_ONLY,
	BA_READ_WRITE,

	BA_MAX
};

class CGPUBuffer
{
public:
	CGPUBuffer(BufferType type, void* data, size_t size, bool isStream = false);
	~CGPUBuffer();

	void Bind();

	void* MapBuffer(BufferAccess access);
	void  UnmapBuffer();

	void UpdateBuffer(void* data, size_t size);

private:

	BufferType m_type;
	uint32_t m_target;
	uint32_t m_buffer;
	size_t m_size;

	bool m_isStream;
};

#endif // !GPU_BUFFER_H
